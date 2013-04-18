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
  module Tasks
    #
    Neo = Napkin::Neo4jUtil
    #
    class TaskBase
      def initialize(task_node_id, pulse_node_id, task_data, task_segment)
        @task_node_id = task_node_id
        @pulse_node_id = pulse_node_id
        @task_data = task_data
        @task_segment = task_segment
      end

      def init?
        return @task_data['napkin.tasks.task_init'].nil?
      end

      def init!
        @task_data['napkin.tasks.task_init'] = true
      end

      #
      # override below in subclass
      #

      def init
      end

      def todo?
        return false
      end

      def doit
      end

    end
  end

  module Handlers
    class Napkin_TaskPostHandler < HandlerBase
      def handle
        param_sub = @query_hash['sub'].first
        # TODO: validate param_sub as good segment
        return nil if param_sub.to_s.empty?

        param_task_class_name = @query_hash['task_class_name'].first
        # TODO: validate param_task_class_name as good segment
        return nil if param_task_class_name.to_s.empty?

        task_node_id = Neo.get_sub_id!(param_sub, @segment_node_id)
        Neo.set_property("napkin.tasks.task_class_name", param_task_class_name, task_node_id)

        return "TaskPostHandler, param_sub: #{param_sub}, param_task_class_name: #{param_task_class_name}"
      end
    end
  end
end