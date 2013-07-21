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
require 'kramdown-util'
require 'napkin-plugins'
require 'napkin-tasks'
require 'napkin-handlers'

# TODO:
# - replace 'Template' and 'template' with service specific identifiers
# - see other plugins for example implementations
# - add require in napkin.rb
module Napkin
  module Plugins
    class Plugin_Template < PluginBase
      def get_segment
        return 'template'
      end

      def get_task_class_name
        return 'Task_Template'
      end
    end
  end

  module Tasks
    class Task_Template < TaskBase
      def init
        root_node_id = Neo.pin(:root)
        template_id = Neo.get_sub_id!('template', root_node_id)
        Neo.set_node_property('napkin.handlers.GET.class_name', 'Handler_Template_Get', template_id)
      end

      def todo?
        return false
      end

      def doit
      end
    end
  end

  module Handlers
    class Handler_Template_Get < DefaultGetHandler
      def handle
        super + "\nTEMPLATE!"
      end
    end
  end
end
