require 'yaml'
require 'rss/2.0'

#
require 'rubygems'
require 'neo4j'
require 'open-uri/cached'

#
require 'napkin-nodewrapper'

module Napkin
  class Tracker
    def initialize
      @code_dir = OpenURI::Cache.cache_path
      @loop_count=0

      git_command("config --file #{@code_dir}/.git/config user.name Fred")
      git_command("config --file #{@code_dir}/.git/config user.email fred@example.com")

      @enabled = true
      @exit = false
      @delay = 5
      @thread = Thread.new do
        begin
          puts "Tracker thread started..."
          helper = RssReader.new
          while (!@exit)
            sleep @delay
            if (@enabled)
              helper.refresh_feeds(@delay)
              puts "Tracker thread refreshed..."
            else
              puts "Tracker thread disabled..."
            end
            do_git_stuff()

            @loop_count += 1
          end
          puts "Tracker thread stopped..."
        rescue StandardError => err
          puts "Error in Tracker thread: #{err}\n#{err.backtrace}"
        end
      end
    end

    def do_git_stuff()
      git_command("init")
      git_command("status -s")
      git_command("add .")
      git_command("commit -m \"...\"")
      git_command("status -s")
      git_command("tag -a loop-#{@loop_count} -m \"...\"")
    end

    def git_command(command, code_dir=@code_dir, git_dir=@code_dir + "/.git")
      command_text = "git --git-dir=#{git_dir} --work-tree=#{code_dir} #{command}"
      result_text = `#{command_text}`
      result_status = $?
      puts "[exec] git ... #{command}\n  -> #{result_status}\n#{result_text}"
    end
  end

  #
  #
  class RssReader
    def refresh_feeds(delay)
      nf = NodeFinder.new
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