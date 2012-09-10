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
      def initialize(node_nav, method, request, segments, segment_index)
        @nn = node_nav
        @method = method
        @request = request
        @segments = segments
        @segment_index = segment_index
      end

      def at_destination?
        return @segments.length() == @segment_index + 1
      end

      def get_segment
        return @segments[@segment_index]
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

        @nn.node.outgoing(NAPKIN_SUB).each do |n|
          puts "CHECK: #{n[NAPKIN_ID]} / #{get_keys(n)}"
          result += "   [sub] --- id:#{n[NAPKIN_ID]}, neo_id:#{n.neo_id}\n"
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