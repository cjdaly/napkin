require 'rss/2.0'
require 'yaml'

#
require 'rubygems'
require 'neo4j'

#
require 'napkin-util'
require 'napkin-common'
require 'napkin-nodenav'
require 'napkin-config'

module Napkin
  module ServerUtils

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
      nn = NodeNav.new
      segments = path.split('/')

      response_text = "[#{segments.length}] "

      current_segment_index = 0
      segments.each_with_index do |segment, i|
        if (nn.go_sub(segment)) then
          #        case method
          #        when :get
          #        when :post
          #        when :put
          #        else
          #        end

          # nn.handle(path, method, request, segments, segment, i)
          response_text += "#{i}:#{segment} / "
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

    def get_node(path)
      content_type 'text/plain'

      nn = NodeNav.new
      if (nn.go_sub_path(path))
        "found: #{nn.get_path()}"
      else
        "not found: #{path} (found: #{nn.get_path()})"
      end
    end

    def post_node(path, content)
      content_type 'text/plain'

      nn = NodeNav.new

      "POST not implemented"
    end

    def put_node(path, content)
      content_type 'text/plain'
      "PUT not implemented"
    end

    def echo_params(path)
      if (path == nil)
        "path: NIL"
      elsif (path =="")
        "path: ''"
      else
        path_segments = path.split('/')
        "path: #{path} -> #{path_segments.join(' : ')}"
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
  end
end

