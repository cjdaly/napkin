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

module Napkin
  module Handlers
    class FeedHandler < HttpMethodHandler
      def handle
        @request.body.rewind
        body_text = @request.body.read
        body_hash = Tracker::FEED_GROUP.yaml_to_hash(body_text, filter=false)

        output_text = subclass_handle(body_hash)
        if (output_text.nil?)
          filtered_text = Tracker::FEED_GROUP.hash_to_yaml(body_hash)
          "!!! HTTP - #{@method}: '#{get_segment}', #{@nn[:id]}\n#{body_text}\n!-->\n#{filtered_text}"
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
        id = body_hash['id']
        return nil if id.nil?

        nn = @nn.dup
        return nil unless nn.go_sub!(id)

        Tracker::FEED_GROUP.hash_to_node(nn.node, body_hash)

        rehash = Tracker::FEED_GROUP.node_to_hash(nn.node)
        Tracker::FEED_GROUP.hash_to_yaml(rehash)
      end
    end

    class FeedPutHandler < FeedHandler
      def subclass_handle(body_hash)
        ""
      end
    end
  end

  class Tracker
    def cycle
      @enabled = true
      @thread = Thread.new do
        begin
          puts "Tracker thread started..."

          # let Neo4J warm up to this thread...
          sleep 5

          init_nodes

          @git_enabled = false
          init_git

          puts "Tracker thread initialized..."
          while (next_cycle)
            puts "Tracker thread - cycle: #{@cycle_count}"
            sleep @pre_cycle_delay_seconds
            if (@enabled)
              refresh_feeds
              puts "Tracker thread refreshed..."
            else
              puts "Tracker thread disabled..."
            end
            do_git_stuff()

            sleep @post_cycle_delay_seconds
          end
          puts "Tracker thread stopped..."
        rescue StandardError => err
          puts "Error in Tracker thread: #{err}\n#{err.backtrace}"
        end
      end
    end

    def next_cycle
      cycle_start_time = Time.now

      nn = Napkin::NodeUtil::NodeNav.new
      nn.reset
      nn.go_sub_path('tracker/cycle')

      @cycle_count = nn['cycle_count']
      @cycle_count += 1
      nn['cycle_count']= @cycle_count

      @pre_cycle_delay_seconds = nn['pre_cycle_delay_seconds']
      @mid_cycle_delay_seconds = nn['mid_cycle_delay_seconds']
      @post_cycle_delay_seconds = nn['post_cycle_delay_seconds']

      nn.go_sub!("#{@cycle_count}")

      nn['cycle_start_time'] = "#{cycle_start_time}"
      nn['cycle_start_time_i'] = cycle_start_time.to_i

      #
      puts ">>> CYCLE: #{nn.get_path} / #{nn['cycle_count']}"

      return true
    end

    def refresh_feeds
      nn_cycle = Napkin::NodeUtil::NodeNav.new
      nn_cycle.go_sub_path("tracker/cycle/#{@cycle_count}")

      nn_feeds = Napkin::NodeUtil::NodeNav.new
      nn_feeds.go_sub_path("tracker/feed")
      nn_feeds.node.outgoing(:sub).each do |sub|
        if sub['feed.refresh_enabled']
          if (time_to_refresh!(sub)) then
            puts "Feed: #{sub[:id]} / #{sub['name']} refreshing..."
            refresh_feed(sub)
            puts "Feed: #{sub[:id]} / #{sub['name']} refreshed..."
            sleep @mid_cycle_delay_seconds
          else
            # puts "Feed: #{sub[:id]} / #{sub['name']} waiting for refresh..."
          end
        else
          puts "Feed: #{sub[:id]} / #{sub['name']} refresh disabled..."
        end
      end
    end

    def time_to_refresh!(feed_node)
      now_time_i = Time.now.to_i

      nn_feed_node = Napkin::NodeUtil::NodeNav.new(feed_node)

      refresh_frequency_minutes = nn_feed_node.
      get_or_init("feed.refresh_frequency_minutes",60)
      refresh_frequency_seconds = refresh_frequency_minutes * 60

      last_refresh_time_i = nn_feed_node.
      get_or_init("feed.last_refresh_time_i",0)

      time_to_refresh_i = last_refresh_time_i + refresh_frequency_seconds

      result = now_time_i > time_to_refresh_i
      if (result) then
        nn_feed_node["feed.last_refresh_time_i"] = now_time_i

        # invalidate the open-uri cache
        feed_url=feed_node['feed.url']
        OpenURI::Cache.invalidate(feed_url)
      else
        seconds_until_refresh = time_to_refresh_i - now_time_i
        puts "Feed: #{feed_node[:id]} / #{feed_node['name']} waiting for refresh in #{seconds_until_refresh} seconds..."
      end
      return result
    end

    def refresh_feed(feed_node)
      begin
        feed_url=feed_node['feed.url']

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

        rss.items.each do |item|
          rss_item_hash = RSS_ITEM_GROUP.construct_hash('rss_item', item)

          # TODO: use lucene
          guid = rss_item_hash['guid']
          item_node = nn_items.node.outgoing(:sub).find{|sub| sub['rss_item.guid'] == guid}

          if(!item_node.nil?) then
            RSS_ITEM_GROUP.hash_to_node(item_node, rss_item_hash)
          else
            Neo4j::Transaction.run do
              item_count = nn_items.get_or_init('item_count',0)
              nn_item = nn_items.dup
              nn_item.go_sub!("#{item_count}")
              RSS_ITEM_GROUP.hash_to_node(nn_item.node, rss_item_hash)
              item_count += 1
              nn_items['item_count'] = item_count
            end
          end

        end
      rescue StandardError => err
        puts "Error in refresh_feed: #{err}\n#{err.backtrace}"
      end
    end

    FEED_GROUP = Napkin::NodeUtil::PropertyGroup.
    new('feed').
    add_property('name').group.
    add_property('url').group.
    add_property('refresh_enabled').group.
    add_property('refresh_frequency_minutes').group.
    add_property('last_refresh_time_i').group

    FILE_META_GROUP = Napkin::NodeUtil::PropertyGroup.new('file_meta').
    add_property('etag').
    add_converter('file_meta_hash',lambda {|fmh|fmh['etag']}).
    add_property('last-modified').
    add_converter('file_meta_hash',lambda {|fmh|fmh['last-modified']}).
    add_property('date').
    add_converter('file_meta_hash',lambda {|fmh|fmh['date']}).
    add_property('expires').
    add_converter('file_meta_hash',lambda {|fmh|fmh['expires']})

    RSS_CHANNEL_GROUP = Napkin::NodeUtil::PropertyGroup.new('rss_channel').
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

    RSS_ITEM_GROUP = Napkin::NodeUtil::PropertyGroup.new('rss_item').
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
    add_converter('rss_item',lambda {|item|item.category.class.name})

    def init_nodes
      nn = Napkin::NodeUtil::NodeNav.new
      nn.go_sub_path!('tracker/feed')
      nn['HTTP-handler-post'] = "FeedPostHandler"
      nn.reset

      nn.go_sub_path!('tracker/cycle')
      nn.get_or_init('cycle_count',0)
      nn.get_or_init('pre_cycle_delay_seconds',9)
      nn.get_or_init('mid_cycle_delay_seconds',5)
      nn.get_or_init('post_cycle_delay_seconds',1)
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