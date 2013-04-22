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
    KEY_MATCH = /^[-_.a-zA-Z0-9~]+$/
    #
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

      def at_destination?
        return @segments.length() == @segment_index + 1
      end

      def get_segment(index = @segment_index)
        return @segments[index]
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

      def get_param(key, validate_as_segment = true)
        param = @query_hash[key].first
        return nil if param.to_s.empty?
        if (validate_as_segment) then
          return nil if KEY_MATCH.match(param).nil?
        end
        return param
      end

      def get_body_text
        @request.body.rewind
        return @request.body.read
      end

      def parse_int(text)
        begin
          return Integer(text)
        rescue ArgumentError => err
          return nil
        end
      end

      def parse_float(text)
        begin
          return Float(text)
        rescue ArgumentError => err
          return nil
        end
      end

      #
      # override below in subclass
      #

      def handle?
        return at_destination?
      end

      def handle
        return nil
      end

    end

    class DefaultGetHandler < HandlerBase
      def handle
        param_key = get_param('key')

        if param_key.nil? then
          return Neo.get_properties_text(@segment_node_id)
        end

        value = Neo.get_property(param_key, @segment_node_id)
        return value.to_s
      end
    end

  end
end
