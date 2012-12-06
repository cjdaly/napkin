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
require 'napkin-extensions'

module Napkin
  module ServerUtils
    def ServerUtils.init_neo4j
      start_time = Time.now

      nn_starts = Napkin::NodeUtil::NodeNav.new
      nn_starts.go_sub_path!('napkin/starts', true)

      nn_cycles = Napkin::NodeUtil::NodeNav.new
      nn_cycles.go_sub_path!('napkin/cycles', true)

      start_count = nn_starts.increment('start_count')

      # let Neo4J warm up...
      sleep 2

      nn_starts.go_sub!("#{start_count}")
      nn_starts['start_time'] = "#{start_time}"
      nn_starts['start_time_i'] = start_time.to_i

      cycle_count = nn_cycles.increment('cycle_count')

      nn_starts['start_cycle_count'] = cycle_count

      # create a startup cycle (for task init?)
      nn_cycles.go_sub!("#{cycle_count}")
      nn_cycles['cycle_start_time'] = "#{start_time}"
      nn_cycles['cycle_start_time_i'] = start_time.to_i
      nn_cycles['init_cycle'] = true

      # let Neo4J warm up...
      sleep 2

      puts "!!! init_neo4j: start: #{start_count} ; cycle #{cycle_count} ; #{start_time}"
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

    def handle_request (path, method, request, user)
      content_type 'text/plain'
      nn = Napkin::NodeUtil::NodeNav.new
      segments = path.split('/')
      response_text = ""

      current_segment_index = 0
      # TODO: use lucene index!
      segments.each_with_index do |segment, i|
        if (nn.go_sub(segment)) then
          handler_class = get_handler_class(nn, method)
          # puts "!!! HTTP handler: #{handler_class.name} as #{user}"
          handler = handler_class.new(nn.dup ,method, request, segments, i, user)
          result = handler.handle

          response_text += "#{result}"
        else
          break
        end
        current_segment_index += 1
      end

      if (current_segment_index != segments.length) then
        if (response_text == "") then
          missing_segment = segments[current_segment_index]
          # halt 404, "Node not found: #{missing_segment} in #{path}"
          response_text += "\nNode not found: #{missing_segment} in #{path}"
        end
      end

      return response_text
    end

    def get_handler_class(nn, method)
      handler_class_name = nn["#{NAPKIN_HTTP_HANDLERS}##{method}"]
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
        return username == password
      end
    end

  end
end

