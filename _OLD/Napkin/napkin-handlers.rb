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

#
require 'rubygems'
require 'neo4j'

#
require 'napkin-config'
require 'napkin-node-util'
require 'napkin-extensions'

module Napkin
  module Handlers
    class HttpMethodHandler
      def initialize(node_nav, method, request, segments, segment_index, user)
        @nn = node_nav
        @method = method
        @request = request
        @segments = segments
        @segment_index = segment_index
        @user = user
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
        return "" unless at_destination?

        query_text = @request.query_string
        query_hash = CGI.parse(query_text)

        prefix = query_hash['prefix'].first

        result = ""
        @nn.node.props.each do |key, value|
          if (key.start_with?(prefix))
            result += ">>> "
          else
            result += "... "
          end
          result += "key:#{key}, value:#{value}\n"
        end

        count = @nn.node.outgoing(NAPKIN_SUB).count
        puts "FIRST (of #{count}):"

        nodes = @nn.node.outgoing(NAPKIN_SUB).sort_by {|n| n.neo_id }
        if (nodes.length > 10) then
          nodes = nodes[-10..-1]
        end

        nodes.each_with_index do |n, i|
          result += "   [sub #{i}] --- id:#{n[NAPKIN_ID]}, neo_id:#{n.neo_id}\n"
        end

        return result
      end

      def get_keys(node)
        result = "("
        node.props.each do |key, value|
          result += "#{key},"
        end
        result += ")"
        return result
      end

    end

  end
end