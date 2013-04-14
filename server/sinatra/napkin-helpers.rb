require 'neo4j-util'
require 'napkin-tasks'
require 'napkin-handlers'

module Napkin
  module Helpers
    #
    Neo = Napkin::Neo4jUtil
    #
    def Helpers.init_neo4j()
      start_time = Time.now

      root_id = Neo.get_root_node_id()
      napkin_id = Neo.get_sub_id!('napkin', root_id)
      starts_id = Neo.get_sub_id!('starts', napkin_id)
      start_node_id = Neo.next_sub_id!(starts_id)

      Neo.set_property('napkin.starts.start_time', "#{start_time}", start_node_id)
      Neo.set_property('napkin.starts.start_time_i', start_time.to_i, start_node_id)

      start_count = Neo.get_property('napkin.sub_count', starts_id)
      puts "STARTS: #{start_count}"

      cycles_id = Neo.get_sub_id!('cycles', napkin_id)
      plugins_id = Neo.get_sub_id!('plugins', napkin_id)

      #TODO: plugin-specific init
      config_id = Neo.get_sub_id!('config', root_id)
      Neo.set_property('napkin.handlers.POST', 'ConfigPostHandler', config_id)
    end

    def Helpers.start_pulse()
      pulse = Napkin::Tasks::Pulse.new
      pulse.start()
    end

    def handle_request (path, request, user)
      content_type 'text/plain'
      segments = path.split('/')

      root_node_id = Neo.get_root_node_id()
      current_node_id = root_node_id
      current_segment_index = 0
      segments.each_with_index do |segment, i|
        next if segment.to_s.empty?

        sub_node_id = nil

        # napkin.segment value may be integer
        segment_i = segment.to_i
        if (segment_i > 0) then
          sub_node_id = Neo.get_sub_id(segment_i, current_node_id)
        end

        # napkin.segment value may be string
        if (sub_node_id.nil?) then
          sub_node_id = Neo.get_sub_id(segment, current_node_id)
        end

        if (!sub_node_id.nil?) then
          current_node_id = sub_node_id

          handler_class = Handlers.get_handler_class(request.request_method, current_node_id)
          if (!handler_class.nil?) then
            handler = handler_class.new(current_node_id, request, segments, i, user)
            if (handler.handle?) then
              result = handler.handle
              return result if !result.nil?
            end
          end
        end
      end

      return Neo.get_properties_text(root_node_id)
    end

    class Authenticator
      def check(username, password)
        return username == password
      end
    end
  end
end
