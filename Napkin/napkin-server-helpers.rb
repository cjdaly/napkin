require 'rss/2.0'
require 'yaml'

#
require 'rubygems'
require 'neo4j'

#
require 'napkin-util'
require 'napkin-common'

module NapkinServerUtils
  NF = NodeFinder.new
  #
  # Feed
  #
  def get_feed(id)
    fp = NapkinCommon::FEED_PROPS
    node = NF.get_sub_path(['feed', id])
    if (node.nil?) then
      halt 404, "Node not found: /feed/#{id}"
    end
    hash = fp.get_hash_for(node)
    return fp.hash_to_yaml(hash)
  end

  def put_feed(id, yaml_text)
    fp = NapkinCommon::FEED_PROPS
    node = NF.get_sub_path(['feed', id], true)
    yaml_hash = fp.yaml_to_hash(yaml_text)
    fp.adorn_node(node, yaml_hash)
    hash = fp.get_hash_for(node)
    return fp.hash_to_yaml(hash)
  end

  #
  # Sketchup
  #
  def get_sketchup_channel_rss(channel_id, group_id="sketchup", server_url="http://localhost:4567")
    rss = RSS::Rss.new("2.0")
    ch = RSS::Rss::Channel.new
    rss.channel = ch

    ch.title="#{channel_id}"
    ch.description = "Feed #{channel_id} description"
    ch.link = "#{server_url}/#{group_id}/#{channel_id}"

    3.times do |n|
      item = RSS::Rss::Channel::Item.new
      item.title = "item#{n}"
      item.link = "#{server_url}/#{group_id}/#{channel_id}/item-#{n}.rb"
      ch.items << item
    end

    return rss.to_s
  end

  def get_sketchup_item_rb(channel_id, item_id)
    "puts \"Here is item-#{item_id} from channel #{channel_id}!\""
  end

end

class Authenticator
  NF = NodeFinder.new
  def check(username, password)
    node = NF.get_sub('user')
    if (node.nil?) then
      return username == 'fred' && password == 'fred'
    end
    node = NF.get_sub(username, node)
    if (node.nil?) then
      return false
    else
      return password == 'fred'
    end
  end
end

class FeedRefresher
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
        puts "FeedReaderThread started..."
        helper = RssReader.new
        while (!@exit)
          sleep @delay
          if (@enabled)
            helper.refresh_feeds(@delay)
            puts "FeedReaderThread refreshed..."
          else
            puts "FeedReaderThread disabled..."
          end
          do_git_stuff()

          @loop_count += 1
        end
        puts "FeedReaderThread stopped..."
      rescue StandardError => err
        puts "Error in FeedRefresher thread: #{err}\n#{err.backtrace}"
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
