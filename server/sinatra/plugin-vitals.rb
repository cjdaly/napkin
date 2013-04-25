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
        vitals_node_id = Neo.get_sub_id!('vitals', Neo.pin(:napkin))
        Neo.set_node_property('napkin.handlers.GET.class_name', 'Handler_Vitals_Get', vitals_node_id)

        @task_data['vitals.sup_node_id'] = vitals_node_id
        @task_data['vitals.skip_count'] = 0
        @task_data['vitals.skip_count_max'] = 6
      end

      def todo?
        skip_count = @task_data['vitals.skip_count'] + 1
        if (skip_count > @task_data['vitals.skip_count_max']) then
          @task_data['vitals.skip_count'] = 0
          return true
        else
          @task_data['vitals.skip_count'] = skip_count
          return false
        end
      end

      MEMFREE_CAPTURE = /^MemFree:\s+(\d+)\skB/

      def doit
        vitals_check_time_i = Time.now.to_i
        vitals_node_id = Neo.next_sub_id!(@task_data['vitals.sup_node_id'])
        Neo.set_node_property('vitals.check_time_i', vitals_check_time_i, vitals_node_id)

        memfree = `cat /proc/meminfo | grep MemFree`
        memfree_kb = MEMFREE_CAPTURE.match(memfree).captures[0]
        memfree_kb_i = parse_int(memfree_kb)
        Neo.set_node_property('vitals.memfree_kb', memfree_kb_i, vitals_node_id)

        loadavg = `cat /proc/loadavg`
        loadavg_split = loadavg.split
        loadavg_1_min = parse_float(loadavg_split[0])
        Neo.set_node_property('vitals.loadavg_1_min', loadavg_1_min, vitals_node_id)
        loadavg_5_min = parse_float(loadavg_split[1])
        Neo.set_node_property('vitals.loadavg_5_min', loadavg_5_min, vitals_node_id)
        loadavg_15_min = parse_float(loadavg_split[2])
        Neo.set_node_property('vitals.loadavg_15_min', loadavg_15_min, vitals_node_id)
      end
    end
  end

  module Handlers
    class Handler_Vitals_Get < DefaultGetHandler
      def handle
        # TODO: return summary of vitals
        return super
      end
    end
  end
end
