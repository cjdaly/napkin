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
require 'napkin-plugins'
require 'napkin-tasks'
require 'napkin-handlers'

module Napkin
  module Plugins
    class Plugin_Config < PluginBase
      def get_segment
        return 'config'
      end

      def get_task_class_name
        return 'Task_Config'
      end
    end
  end

  module Tasks
    class Task_Config < TaskBase
      def init
        root_node_id = Neo.pin(:root)
        config_id = Neo.get_sub_id!('config', root_node_id)
        Neo.set_node_property('napkin.handlers.POST.class_name', 'Handler_Config_Post', config_id)
      end

      def todo?
        return false
      end

      def doit
      end
    end
  end

  module Handlers
    class Handler_Config_Post < HandlerBase
      def handle
        param_sub = get_param('sub')
        return nil if param_sub.nil?

        sub_node_id = Neo.get_sub_id!(param_sub, @segment_node_id)
        Neo.set_node_property('napkin.handlers.POST.class_name', 'Handler_Config_Post', sub_node_id)
        Neo.set_node_property('napkin.handlers.PUT.class_name', 'Handler_Config_Put', sub_node_id)
        Neo.set_node_property('napkin.handlers.GET.class_name', 'Handler_Config_Get', sub_node_id)

        return "OK"
      end
    end

    class Handler_Config_Put < HandlerBase
      def handle
        param_key = get_param('key')
        return nil if param_key.nil?

        value = get_body_text

        if (KEY_TYPE_I_MATCH.match(param_key) != nil) then
          value = parse_int(value)
        elsif (KEY_TYPE_F_MATCH.match(param_key) != nil) then
          value = parse_float(value)
        end

        Neo.set_node_property(param_key, value, @segment_node_id) unless value.nil?

        return "OK"
      end
    end

    class Handler_Config_Get < DefaultGetHandler
    end
  end
end
