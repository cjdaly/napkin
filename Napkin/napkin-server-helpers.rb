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

      nn_starts = Napkin::NodeUtil::NodeNav.new
      nn_starts.go_sub_path!('napkin/starts', true)

      nn_cycles = Napkin::NodeUtil::NodeNav.new
      nn_cycles.go_sub_path!('napkin/cycles', true)

      start_count = nn_starts.get_or_init('start_count',-1)
      start_count += 1
      nn_starts['start_count'] = start_count

      # let Neo4J warm up...
      sleep 2

      nn_starts.go_sub!("#{start_count}")
      nn_starts['start_time'] = "#{start_time}"
      nn_starts['start_time_i'] = start_time.to_i

      cycle_count = nn_cycles.get_or_init('cycle_count',-1)
      cycle_count += 1
      nn_cycles['cycle_count'] = cycle_count

      nn_starts['start_cycle_count'] = cycle_count

      # create a startup cycle (for task init?)
      nn_cycles.go_sub!("#{cycle_count}")
      nn_cycles['cycle_start_time'] = "#{start_time}"
      nn_cycles['cycle_start_time_i'] = start_time.to_i

      # let Neo4J warm up...
      sleep 2

      puts "!!! init_neo4j: start: #{start_count} ; #{nn_starts.get_path()} ; #{start_time}"
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

