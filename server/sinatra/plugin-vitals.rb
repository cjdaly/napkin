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
    class Plugin_Vitals < PluginBase
      def get_segment
        return 'vitals'
      end

      def get_task_class_name
        return 'Task_Vitals'
      end
    end
  end

  module Tasks
    class Task_Vitals < TaskBase
      def init
        napkin_node_id = Neo.pin(:napkin)
        vitals_id = Neo.get_sub_id!('vitals', napkin_node_id)
        Neo.set_property('napkin.handlers.GET.class_name', 'Handler_Vitals_Get', vitals_id)
      end

      def todo?
        puts "Task_Vitals"
        return false
      end

      def doit
      end
    end
  end

  module Handlers
    class Handler_Vitals_Get < HandlerBase
      def handle
        puts "Handler_Vitals_Get!!!"
      end
    end
  end
end
