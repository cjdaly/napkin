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
    class Plugin_Chatter < PluginBase
      def get_segment
        return 'chatter'
      end

      def get_task_class_name
        return 'Task_Chatter'
      end
    end
  end

  module Tasks
    class Task_Chatter < TaskBase
      def init
        napkin_node_id = Neo.pin(:napkin)
        chatter_id = Neo.get_sub_id!('chatter', napkin_node_id)
        Neo.set_property('napkin.handlers.POST.class_name', 'Handler_Chatter_Post', chatter_id)
      end

      def todo?
        puts "Task_Chatter"
        return false
      end

      def doit
      end
    end
  end

  module Handlers
    class Handler_Chatter_Post < HandlerBase
      def handle
      end
    end
  end
end