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
        ""
      end
    end

    class EndpointEchoHandler < HttpMethodHandler
      def handle
        "!!! HTTP - #{@method}: '#{get_segment}', #{@nn[:id]}"
      end
    end

  end
end