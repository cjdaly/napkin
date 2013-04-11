require 'neo4j-util'
require 'napkin-handlers'

module Napkin
  module Handlers
    class ConfigPostHandler < HandlerBase
      def handle
        param_sub = @query_hash['sub'].first
        # TODO: validate param_sub as good segment
        return nil if param_sub.to_s.empty?

        sub_node_id = Neo.get_sub_id!(param_sub, @node_id)
        Neo.set_property('napkin.handlers.POST', 'ConfigPostHandler', sub_node_id)
        Neo.set_property('napkin.handlers.PUT', 'ConfigPutHandler', sub_node_id)
        Neo.set_property('napkin.handlers.GET', 'ConfigGetHandler', sub_node_id)

        return "ConfigPostHandler, param_sub: #{param_sub}"
      end
    end

    class ConfigPutHandler < HandlerBase
      def handle
        param_key = @query_hash['key'].first
        # TODO: validate param_sub as good segment
        return nil if param_key.to_s.empty?

        @request.body.rewind
        value = @request.body.read
        
        Neo.set_property(param_key, value, @node_id)

        return "ConfigPutHandler, param_key: #{param_key}\n#{value}"
      end
    end

    class ConfigGetHandler < HandlerBase
      def handle
        param_key = @query_hash['key'].first
        # TODO: validate param_sub as good segment
        return nil if param_key.to_s.empty?

        value = Neo.get_property(param_key, @node_id)

        return "ConfigGetHandler, param_key: #{param_key}\n#{value}"
      end
    end
  end
end
