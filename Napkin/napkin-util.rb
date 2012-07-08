require 'yaml'
require 'rss/2.0'

#
require 'rubygems'
require 'neo4j'
require 'open-uri/cached'

OpenURI::Cache.cache_path = 'open-uri-cache'

#
#
class PropertyMapper
  def initialize(keys)
    @keys=keys
  end

  def get_hash_for(node)
    hash = {}
    @keys.each do |key|
      hash[key] = node[key]
    end
    return hash
  end

  def yaml_to_hash(yaml_text)
    yaml = YAML.load(yaml_text)
    out = {}
    @keys.each do |key|
      val = yaml[key]
      if (!val.nil?) then
        out[key] = val
      end
    end
    return out
  end

  def hash_to_yaml(hash)
    return YAML.dump(hash)
  end

  def adorn_node(node, hash)
    Neo4j::Transaction.run do
      @keys.each do |key|
        node[key] = hash[key]
      end
    end
  end
end

#
#
class NodeFinder
  def get_sub(id, node=Neo4j.ref_node, create_if_absent=false)
    sub = node.outgoing(:sub).find{|sub| sub[:id] == id}
    if (sub.nil? && create_if_absent) then
      sub = create_sub(id, node)
    end
    return sub
  end

  def get_sub_path(path, create_if_absent=false)
    sub=Neo4j.ref_node
    path.each do |id|
      sub = get_sub(id, sub, create_if_absent)
      puts "got #{sub} for #{id}"
      break if sub.nil?
    end
    return sub
  end

  def create_sub(id, node)
    sub=nil
    Neo4j::Transaction.run do
      sub = node.outgoing(:sub).find{|sub| sub[:id] == id}
      if (sub.nil?) then
        sub = Neo4j::Node.new :id => id
        node.outgoing(:sub) << sub
      end
    end
    return sub
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
