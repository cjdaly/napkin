require 'yaml'
require 'rss/2.0'

#
require 'rubygems'
require 'neo4j'
require 'open-uri/cached'

#
require 'napkin-config'
require 'napkin-node-util'

module Napkin
  class Tracker
    def init_nodes
      nn = Napkin::NodeUtil::NodeNav.new
      nn.go_sub_path!('tracker/feed')
      nn.reset

      nn.go_sub_path!('tracker/cycle')
      nn.get_or_init('cycle_count',0)
      nn.get_or_init('pre_cycle_delay_seconds',5)
      nn.get_or_init('post_cycle_delay_seconds',1)
    end

    def init_git
      @cache_dir = OpenURI::Cache.cache_path
      git_command("config --file #{@cache_dir}/.git/config user.name Fred")
      git_command("config --file #{@cache_dir}/.git/config user.email fred@example.com")
    end

    def cycle
      @enabled = true
      @thread = Thread.new do
        begin
          puts "Tracker thread started..."

          # Some sleepage seems to be necessary to avoid strange Neo4J exceptions...
          sleep 1

          init_nodes
          init_git

          puts "Tracker thread initialized..."

          @n = Napkin::NodeUtil::NodeNav.new
          # helper = RssReader.new
          while (next_cycle)
            puts "Tracker thread - cycle: #{@cycle_count}, path: #{@n.get_path}"
            sleep @pre_cycle_delay_seconds
            if (@enabled)
              # helper.refresh_feeds(@delay)
              puts "Tracker thread refreshed..."
            else
              puts "Tracker thread disabled..."
            end
            # do_git_stuff()

            sleep @post_cycle_delay_seconds
          end
          puts "Tracker thread stopped..."
        rescue StandardError => err
          puts "Error in Tracker thread: #{err}\n#{err.backtrace}"
        end
      end
    end

    def next_cycle
      @n.reset
      result = @n.go_sub_path('tracker/cycle')
      puts "!!! #{result} / #{@n.get_path} / #{@n['cycle_count']}"

      @cycle_count = @n['cycle_count']
      @cycle_count += 1
      @n['cycle_count']= @cycle_count

      #
      puts "!!! #{@n.get_path} / #{@n['cycle_count']}"

      @pre_cycle_delay_seconds = @n['pre_cycle_delay_seconds']
      @post_cycle_delay_seconds = @n['post_cycle_delay_seconds']

      return true
    end

    def do_git_stuff()
      git_command("init")
      git_command("status -s")
      git_command("add .")
      git_command("commit -m \"...\"")
      git_command("status -s")
      git_command("tag -a loop-#{@cycle_count} -m \"...\"")
    end

    def git_command(command, cache_dir=@cache_dir, git_dir=@cache_dir + "/.git")
      command_text = "git --git-dir=#{git_dir} --work-tree=#{cache_dir} #{command}"
      result_text = `#{command_text}`
      result_status = $?
      puts "[exec] git ... #{command}\n  -> #{result_status}\n#{result_text}"
    end
  end

  #
  #
  class RssReader
    def refresh_feeds(delay)
      nf = Napkin::NodeUtil::NodeFinder.new
      node = nf.get_sub('feed')
      if (!node.nil?)
        node.outgoing(:sub).each do |sub|
          if sub['refresh_enabled']
            puts "Feed: #{sub[:id]} / #{sub['name']} refreshing..."
            refresh_feed(sub)
            puts "Feed: #{sub[:id]} / #{sub['name']} refreshed..."
          else
            puts "Feed: #{sub[:id]} / #{sub['name']} refresh disabled..."
          end
          sleep delay
        end
      end
    end

    def refresh_feed(feed_node)
      feed_url=feed_node['url']
      rss_file_meta_hash = nil
      open(feed_url) do |rss_file|
        rss_file_meta_hash = file_meta_to_hash(rss_file.meta)
      end
      puts YAML.dump(rss_file_meta_hash)
    end

    def refresh_feep(feed_id)
      begin

        # TODO: get file meta info, get refresh info, ... time to refresh?

        # TODO:
        feed_url=nil

        rss_file_meta_hash = nil
        rss_text = nil
        open(feed_url) do |rss_file|
          rss_file_meta_hash = file_meta_to_hash(rss_file.meta)
          rss_text = rss_file.read
        end

        # TODO:
        # invalidate cache at refresh time
        #   OpenURI::Cache.invalidate(@feed_url)
        # ... and open/read again
        # ... update file meta in db

        rss = RSS::Parser.parse(rss_text, false)

        rss_channel_hash = channel_to_hash(rss.channel)
        # TODO: compare with existing / update

        rss.items.each do |item|
          rss_item_hash = item_to_hash(item)
          # TODO: compare with existing / update
        end
      rescue StandardError => err
        puts "Error in refresh_feed: #{err}\n#{err.backtrace}"
      end
    end

    def file_meta_to_hash(file_meta)
      return {
        'etag' => file_meta['etag'],
        'last-modified' => file_meta['last-modified'],
        'date' => file_meta['date'],
        'expires' => file_meta['expires'],
      }
    end

    def channel_to_hash(rss_channel)
      return {
        'title' => rss_channel.title,
        'link'=> rss_channel.link,
        'description' => rss_channel.description,
        'pubDate' => rss_channel.pubDate,
        'lastBuildDate' => rss_channel.pubDate
      }
    end

    def item_to_hash(rss_item)
      return {
        'title' => rss_item.title,
        'link'=> rss_item.link,
        'description' => rss_item.description,
        'guid' => rss_item.guid.content,
        'pubDate' => rss_item.pubDate
      }
    end

    #  def puts_meta(meta, attr)
    #    # pd = ParseDate.parsedate(meta[attr])
    #    # puts pd
    #    d = DateTime.parse(meta[attr])
    #    d2 = DateTime.now - d
    #    puts attr + ": " + meta[attr]
    #    puts (d2 * 24 * 60).to_i
    #  end
  end
end