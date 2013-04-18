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
require 'napkin-tasks'

module Napkin
  module Plugins
    #
    Neo = Napkin::Neo4jUtil
    #
    class PluginBase
      def initialize()
      end

      #
      # override below in subclass
      #

      def get_segment
        return nil
      end

      def get_task_class_name
        return nil
      end
    end

    def Plugins.init()
      mod = Napkin::Plugins
      mod.constants.each do |c_name|
        c_obj = mod.const_get(c_name)
        if ((c_obj.is_a? Class) && (c_obj < PluginBase)) then
          plugin = c_obj.new()
          task_node_id = Neo.get_sub_id!(plugin.get_segment, Neo.pin(:tasks))
          Neo.set_property('napkin.tasks.task_class_name', plugin.get_task_class_name, task_node_id)
        end
      end
    end

  end
end