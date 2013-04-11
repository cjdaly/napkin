require 'neo4j-util'
require 'napkin-handlers'

module Napkin
  module Helpers
    #
    Neo = Napkin::Neo4jUtil
    #
    def Helpers.init_neo4j()
      puts "init_neo4j!"
      napkin_id = Neo.get_sub_id!('napkin')
      starts_id = Neo.get_sub_id!('starts', napkin_id)
      cycles_id = Neo.get_sub_id!('cycles', napkin_id)
      plugins_id = Neo.get_sub_id!('plugins', napkin_id)
      
      #TODO: plugin-specific init
      config_id = Neo.get_sub_id!('config')
      Neo.set_property('napkin.handlers.POST', 'ConfigPostHandler', config_id)

      start_count = Neo.increment_counter('napkin.starts.count', starts_id)
      puts "STARTS: #{start_count}"
    end

    def handle_request (path, request, user)
      content_type 'text/plain'
      segments = path.split('/')

      current_segment_index = 0
      current_node_id = 0
      segments.each_with_index do |segment, i|
        next if segment.to_s.empty?

        sub_node_id = Neo.get_sub_id(segment, current_node_id)
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

          puts "SUB: #{segment} : #{current_node_id} in #{path}"
        else
          puts "No SUB: #{segment} in #{path}"
        end
      end

      response_text = "#{path} #{request.request_method} #{user}\n"
      return response_text
    end

    class Authenticator
      def check(username, password)
        return username == password
      end
    end
  end
end
