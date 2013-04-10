require 'cgi'
require 'neo4j-util'

module Napkin
  module Handlers
    #
    Neo = Napkin::Neo4jUtil
    #
    def Handlers.get_handler_class(method, node_id)
      handler_class_name = Neo.get_property("napkin.handlers.#{method}", node_id)
      if (handler_class_name.nil?) then
        return (method == "GET") ? DefaultGetHandler : nil
      end

      handler_class = Napkin::Handlers.const_get(handler_class_name)
      if (handler_class.nil?) then
        return (method == "GET") ? DefaultGetHandler : nil
      end

      return handler_class
    end

    class HandlerBase
      def initialize(node_id, request, segments, segment_index, user)
        @node_id = node_id
        @request = request
        @segments = segments
        @segment_index = segment_index
        @user = user
        @query_hash = CGI.parse(@request.query_string)
      end

      def handle_at_destination_only
        return true
      end

      def at_destination?
        return @segments.length() == @segment_index + 1
      end

      def next_stop_destination?
        return @segments.length() == @segment_index + 2
      end

      def get_segment(index = @segment_index)
        return @segments[index]
      end

      def get_next_segment
        return get_segment(@segment_index + 1)
      end

      def get_path(start_index=0, end_index=-1)
        if (end_index == -1) then
          end_index = @segments.length - 1
        end

        path = ""
        index = start_index
        while index <= end_index do
          if path != "" then
            path << "/"
          end
          path << @segments[index]
          index += 1
        end
        return path
      end

      def get_current_path
        return get_path(0, @segment_index)
      end

      def handle
        return nil
      end

    end

    class DefaultGetHandler < HandlerBase
      def handle
        return nil unless at_destination?

        return "DefaultGetHandler: #{@node_id} , #{get_segment}"
      end
    end

  end
end
