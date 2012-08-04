require 'cgi'

#
require 'rubygems'
require 'neo4j'

#
require 'napkin-config'
require 'napkin-node-util'

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

        prefix = query_hash['prefix'] || "."

        result = ""
        @nn.node.props.each do |key, value|
          if (key.start_with?(prefix))
            result += ">>> "
          else
            result += "... "
          end
          result += "key:#{key}, value:#{value}\n"
        end
        return result
      end
    end

  end
end