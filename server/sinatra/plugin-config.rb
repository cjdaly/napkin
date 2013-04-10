require 'neo4j-util'
require 'napkin-handlers'

module Napkin
  module Handlers
    class ConfigPostHandler < HandlerBase
      def handle
        return nil unless at_destination?

        param_sub = @query_hash['sub'].first
        return nil if param_sub.to_s.empty?

        #        nn = @nn.dup
        #        if (nn.go_sub!(param_sub)) then
        #          nn[NAPKIN_HTTP_POST] = "ConfigPostHandler"
        #          nn[NAPKIN_HTTP_PUT] = "ConfigPutHandler"
        #          nn[NAPKIN_HTTP_GET] = "ConfigGetHandler"
        #        end

        return "ConfigPostHandler"
      end
    end

    class ConfigPutHandler < HandlerBase
      def handle
        return nil unless at_destination?

        param_key = @query_hash['key'].first
        return nil if param_key.to_s.empty?

        @request.body.rewind
        body_text = @request.body.read

        #        nn = @nn.dup
        #        # TODO: bad hash slash
        #        old_value = nn["config/data##{param_key}"]
        #        # TODO: bad hash slash
        #        nn["config/data##{param_key}"] = body_text
        #
        #        old_value="" if old_value.nil?
        #        return old_value.to_s

        return "ConfigPutHandler"
      end
    end

    class ConfigGetHandler < HandlerBase
      def handle
        return nil unless at_destination?

        param_key = @query_hash['key'].first
        return nil if param_key.to_s.empty?

        #        nn = @nn.dup
        #        # TODO: bad hash slash
        #        value = nn["config/data##{param_key}"]
        #
        #        value="" if value.nil?
        #        return value.to_s

        return "ConfigGetHandler"
      end
    end
  end
end
