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
        end
        puts "FeedReaderThread stopped..."
      rescue StandardError => err
        puts "Error in FeedRefresher thread: #{err}\n#{err.backtrace}"
      end
    end
  end
end
