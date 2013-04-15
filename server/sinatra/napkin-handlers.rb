####
# Copyright (c) 2013 Chris J Daly (github user cjdaly)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   cjdaly - initial API and implementation
####
require 'cgi'
require 'neo4j-util'

module Napkin
  module Handlers
    #
    Neo = Napkin::Neo4jUtil
    #
    def Handlers.get_handler_class(method, segment_node_id)
      handler_class_name = Neo.get_property("napkin.handlers.#{method}", segment_node_id)
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
      def initialize(segment_node_id, handle_node_id, request, segments, segment_index, user)
        @segment_node_id = segment_node_id
        @handle_node_id = handle_node_id
        @request = request
        @segments = segments
        @segment_index = segment_index
        @user = user
        @query_hash = CGI.parse(@request.query_string)
      end

      def handle?
        return at_destination?
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
        return Neo.get_properties_text(@segment_node_id)
      end
    end

  end
end
