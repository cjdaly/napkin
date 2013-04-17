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
require 'neo4j-util'
require 'napkin-handlers'

module Napkin
  module Handlers
    class ConfigPostHandler < HandlerBase
      def handle
        param_sub = @query_hash['sub'].first
        # TODO: validate param_sub as good segment
        return nil if param_sub.to_s.empty?

        sub_node_id = Neo.get_sub_id!(param_sub, @segment_node_id)
        Neo.set_property('napkin.handlers.POST.class_name', 'ConfigPostHandler', sub_node_id)
        Neo.set_property('napkin.handlers.PUT.class_name', 'ConfigPutHandler', sub_node_id)
        Neo.set_property('napkin.handlers.GET.class_name', 'ConfigGetHandler', sub_node_id)

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

        Neo.set_property(param_key, value, @segment_node_id)

        return "ConfigPutHandler, param_key: #{param_key}\n#{value}"
      end
    end

    class ConfigGetHandler < HandlerBase
      def handle
        param_key = @query_hash['key'].first
        # TODO: validate param_sub as good segment
        if param_key.to_s.empty? then
          return Neo.get_properties_text(@segment_node_id)
        end

        value = Neo.get_property(param_key, @segment_node_id)
        return value
      end
    end
  end
end
