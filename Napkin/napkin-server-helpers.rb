require 'rss/2.0'
require 'yaml'
require 'date'

#
require 'rubygems'
require 'neo4j'

#
require 'napkin-config'
require 'napkin-node-util'
require 'napkin-handlers'

module Napkin
  module ServerUtils
    def ServerUtils.init_neo4j
      start_time = Time.now

      nn = Napkin::NodeUtil::NodeNav.new
      nn.go_sub_path!('napkin/starts')

      start_count = nn.get_or_init('start_count',0)
      start_count += 1
      nn['start_count'] = start_count

      nn.go_sub!("#{start_count}")
      nn['start_time'] = "#{start_time}"
      nn['start_time_i'] = start_time.to_i

      # let Neo4J warm up...
      sleep 5

      puts "!!! init_neo4j: start: #{start_count} ; #{nn.get_path()} ; #{start_time}"
    end

    #    NF = Napkin::NodeUtil::NodeFinder.new
    #
    #    #
    #    # Feed
    #    #
    #    def get_feed(id)
    #      fp = Napkin::NodeUtil::Props::FEED_PROPS
    #      node = NF.get_sub_path(['feed', id])
    #      if (node.nil?) then
    #        halt 404, "Node not found: /feed/#{id}"
    #      end
    #      hash = fp.get_hash_for(node)
    #      return fp.hash_to_yaml(hash)
    #    end
    #
    #    def put_feed(id, yaml_text)
    #      fp = Napkin::NodeUtil::Props::FEED_PROPS
    #      node = NF.get_sub_path(['feed', id], true)
    #      yaml_hash = fp.yaml_to_hash(yaml_text)
    #      fp.adorn_node(node, yaml_hash)
    #      hash = fp.get_hash_for(node)
    #      return fp.hash_to_yaml(hash)
    #    end

    #
    # Sketchup
    #
    def get_sketchup_channel_rss(channel_id, group_id="sketchup", server_url=Napkin::Config::ROOT_URL)
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

    def handle_request (path, method, request)
      content_type 'text/plain'
      nn = Napkin::NodeUtil::NodeNav.new
      segments = path.split('/')
      response_text = ""

      current_segment_index = 0
      segments.each_with_index do |segment, i|
        if (nn.go_sub(segment)) then
          handler_class = get_handler_class(nn, method)
          handler = handler_class.new(nn.dup ,method, request, segments, i)
          result = handler.handle

          response_text += "#{result}"
        else
          break
        end
        current_segment_index += 1
      end

      if (current_segment_index != segments.length) then
        missing_segment = segments[current_segment_index]
        halt 404, "Node not found: #{missing_segment} in #{path}"
      else
        return response_text
      end
    end

    def get_handler_class(nn, method)
      puts "!!! Searching for handler: HTTP-handler-#{method}"
      handler_class_name = nn["HTTP-handler-#{method}"]
      if (handler_class_name.nil?) then
        return Napkin::Handlers::HttpMethodHandler
      end

      handler_class = Napkin::Handlers.const_get(handler_class_name)
      if (handler_class.nil?) then
        return Napkin::Handlers::HttpMethodHandler
      end

      return handler_class
    end

    class Authenticator
      def check(username, password)
        return username == 'fred' && password == 'fred'
      end
    end

  end
end

