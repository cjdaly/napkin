require 'yaml'
require 'rss/2.0'

#
require 'rubygems'
require 'neo4j'
require 'open-uri/cached'

#
require 'napkin-config'
require 'napkin-node-util'
require 'napkin-handlers'
require 'napkin-extensions'

module Napkin
  module Handlers
    class FeedHandler < HttpMethodHandler
      def handle
        return "" unless at_destination?

        @request.body.rewind
        body_text = @request.body.read
        body_hash = Napkin::Extensions::Tasks::TrackerTask::FEED_GROUP.yaml_to_hash(body_text, filter=false)

        output_text = subclass_handle(body_hash)
        if (output_text.nil?)
          filtered_text = Napkin::Extensions::Tasks::TrackerTask::FEED_GROUP.hash_to_yaml(body_hash)
          "!!! HTTP - #{@method}: '#{get_segment}', #{@nn[NAPKIN_ID]}\n#{body_text}\n!-->\n#{filtered_text}"
        else
          return output_text
        end
      end

      def subclass_handle(body_hash)
        return nil
      end
    end

    class FeedPostHandler < FeedHandler
      def subclass_handle(body_hash)
        id = body_hash[NAPKIN_ID]
        return "FeedPostHandler: missing id!" if id.nil?

        nn = @nn.dup
        nn.go_sub!(id)

        Napkin::Extensions::Tasks::TrackerTask::FEED_GROUP.hash_to_node(nn.node, body_hash)

        output_hash = Napkin::Extensions::Tasks::TrackerTask::FEED_GROUP.node_to_hash(nn.node)
        output_text = Napkin::Extensions::Tasks::TrackerTask::FEED_GROUP.hash_to_yaml(output_hash)
        return output_text
      end
    end

    class FeedPutHandler < FeedHandler
      def subclass_handle(body_hash)
        ""
      end
    end
  end

  module Extensions
    module Tasks
      class TrackerTask < Task
        def init
          super
          puts "!!! TrackerTask.init called !!!"
          init_nodes
        end

        def cycle
          super
          puts "!!! TrackerTask.cycle called !!!"
          refresh_feeds
        end

        def refresh_feeds
          nn_feeds = Napkin::NodeUtil::NodeNav.new
          nn_feeds.go_sub_path!("tracker/feeds")
          nn_feeds.node.outgoing(NAPKIN_SUB).each do |sub|
            feed_id = sub[NAPKIN_ID]
            feed_name = FEED_GROUP.get(sub, 'name')
            refresh_enabled = FEED_GROUP.get(sub, 'refresh_enabled')

            if (refresh_enabled) then
              if (time_to_refresh!(sub)) then
                puts "Feed: #{feed_id} / #{feed_name} refreshing..."
                refresh_feed(sub)
                puts "Feed: #{feed_id} / #{feed_name} refreshed..."

                mid_cycle_delay_seconds = 2 # TODO
                sleep mid_cycle_delay_seconds
              else
                # puts "Feed: #{feed_id} / #{feed_name} waiting for refresh..."
              end
            else
              puts "Feed: #{feed_id} / #{feed_name} refresh disabled..."
            end
          end
        end

        def time_to_refresh!(feed_node)
          now_time_i = Time.now.to_i

          feed_id = feed_node[NAPKIN_ID]
          feed_name = FEED_GROUP.get(feed_node, 'name')

          refresh_frequency_minutes = FEED_GROUP.get_or_init(feed_node, 'refresh_frequency_minutes', 60)
          refresh_frequency_seconds = refresh_frequency_minutes * 60

          last_refresh_time_i = FEED_GROUP.get_or_init(feed_node, 'last_refresh_time_i', 0)

          time_to_refresh_i = last_refresh_time_i + refresh_frequency_seconds

          result = now_time_i > time_to_refresh_i
          if (result) then
            FEED_GROUP.set(feed_node, 'last_refresh_time_i', now_time_i)

            # invalidate the open-uri cache
            feed_url= FEED_GROUP.get(feed_node, 'url')
            OpenURI::Cache.invalidate(feed_url)
          else
            seconds_until_refresh = time_to_refresh_i - now_time_i
            puts "Feed: #{feed_id} / #{feed_name} waiting for refresh in #{seconds_until_refresh} seconds..."
          end
          return result
        end

        def refresh_feed(feed_node)
          begin
            feed_url= FEED_GROUP.get(feed_node, 'url')

            rss_file_meta_hash = nil
            rss_text = nil
            open(feed_url) do |rss_file|
              rss_file_meta_hash = FILE_META_GROUP.
              construct_hash('file_meta_hash', rss_file.meta)

              rss_text = rss_file.read
            end
            FILE_META_GROUP.hash_to_node(feed_node, rss_file_meta_hash)

            rss = RSS::Parser.parse(rss_text, false)

            rss_channel_hash = RSS_CHANNEL_GROUP.construct_hash('rss_channel', rss.channel)
            nn_channel = Napkin::NodeUtil::NodeNav.new(feed_node)
            nn_channel.go_sub!('channel');
            RSS_CHANNEL_GROUP.hash_to_node(nn_channel.node, rss_channel_hash)

            nn_items = Napkin::NodeUtil::NodeNav.new(feed_node)
            nn_items.go_sub!('items');
            nn_items.set_key_prefix('tracker/feeds/feed/items')

            rss.items.each do |item|
              rss_item_hash = RSS_ITEM_GROUP.construct_hash('rss_item', item)

              guid = rss_item_hash['tracker/feeds/rss_item#guid']
              item_node = nil
              nodes = RSSItemIndex.find('tracker/feeds/rss_item#guid' => guid)
              nodes.each do |n|
                if (Napkin::NodeUtil::NodeNav.get_sup(n) == nn_items.node)
                  item_node = n
                end
              end

              if(!item_node.nil?) then
                RSS_ITEM_GROUP.hash_to_node(item_node, rss_item_hash)
                puts "refresh_feed: FOUND #{guid}"
              else
                Neo4j::Transaction.run do
                  item_count = nn_items.get_or_init('item_count',-1)
                  item_count += 1
                  nn_items['item_count'] = item_count

                  nn_item = nn_items.dup
                  nn_item.go_sub!("#{item_count}")
                  RSS_ITEM_GROUP.hash_to_node(nn_item.node, rss_item_hash)
                end
                puts "refresh_feed: NEW #{guid}"
              end

            end
          rescue StandardError => err
            puts "Error in refresh_feed: #{err}\n#{err.backtrace}"
          end
        end

        FEED_GROUP = Napkin::NodeUtil::PropertyGroup.new('tracker/feeds/feed').
        add_property('name').group.
        add_property('url').group.
        add_property('refresh_enabled').group.
        add_property('refresh_frequency_minutes').group.
        add_property('last_refresh_time_i').group

        FILE_META_GROUP = Napkin::NodeUtil::PropertyGroup.new('tracker/feeds/file_meta').
        add_property('etag').
        add_converter('file_meta_hash',lambda {|fmh|fmh['etag']}).
        add_property('last-modified').
        add_converter('file_meta_hash',lambda {|fmh|fmh['last-modified']}).
        add_property('date').
        add_converter('file_meta_hash',lambda {|fmh|fmh['date']}).
        add_property('expires').
        add_converter('file_meta_hash',lambda {|fmh|fmh['expires']})

        RSS_CHANNEL_GROUP = Napkin::NodeUtil::PropertyGroup.new('tracker/feeds/rss_channel').
        add_property('title').
        add_converter('rss_channel',lambda {|ch|ch.title}).
        add_property('link').
        add_converter('rss_channel',lambda {|ch|ch.link}).
        add_property('description').
        add_converter('rss_channel',lambda {|ch|ch.description}).
        add_property('pubDate').
        add_converter('rss_channel',lambda {|ch|ch.pubDate.to_s}).
        add_property('lastBuildDate').
        add_converter('rss_channel',lambda {|ch|ch.lastBuildDate.to_s}).
        add_property('category').
        add_converter('rss_channel',lambda {|ch|ch.category.class.name})

        RSS_ITEM_GROUP = Napkin::NodeUtil::PropertyGroup.new('tracker/feeds/rss_item').
        add_property('title').
        add_converter('rss_item',lambda {|item|item.title}).
        add_property('link').
        add_converter('rss_item',lambda {|item|item.link}).
        add_property('description').
        add_converter('rss_item',lambda {|item|item.description}).
        add_property('guid').
        add_converter('rss_item',lambda {|item|item.guid.content}).
        add_property('pubDate').
        add_converter('rss_item',lambda {|item|item.pubDate.to_s}).
        add_property('category').
        add_converter('rss_item',lambda {|item|item.category.class.name}).
        add_property('_index').
        add_converter('rss_item',lambda {|item|true})

        class RSSItemIndex
          extend Neo4j::Core::Index::ClassMethods
          include Neo4j::Core::Index

          self.node_indexer do
            index_names :exact => 'tracker_feeds_rss_item'
            trigger_on 'tracker/feeds/rss_item#_index' => true
          end

          index 'tracker/feeds/rss_item#guid'
        end

        def init_nodes
          nn = Napkin::NodeUtil::NodeNav.new
          nn.go_sub_path!('tracker/feeds')
          nn[NAPKIN_HTTP_POST] = "FeedPostHandler"
        end

        #
        # Git stuff
        #

        def init_git
          return unless @git_enabled

          @cache_dir = Napkin::Config::OPEN_URI_CACHE_PATH
          git_command("init")
          git_command("config --file #{@cache_dir}/.git/config user.name #{Napkin::Config::GIT_USER_NAME}")
          git_command("config --file #{@cache_dir}/.git/config user.email #{Napkin::Config::GIT_USER_EMAIL}")
        end

        def do_git_stuff()
          return unless @git_enabled

          git_command("status -s")
          git_command("add .")
          git_command("commit -m \"...\"")
          git_command("status -s")
          git_command("tag -a cycle_#{@cycle_count} -m \"...\"")
        end

        def git_command(command, cache_dir=@cache_dir, git_dir=@cache_dir + "/.git")
          return unless @git_enabled

          command_text = "git --git-dir=#{git_dir} --work-tree=#{cache_dir} #{command}"
          result_text = `#{command_text}`
          result_status = $?
          if (result_status != 0)
            puts "[exec] git ... #{command}\n  -> #{result_status}\n#{result_text}"
          end
        end
      end
    end
  end
end