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

      def parse_int(text)
        begin
          return Integer(text)
        rescue ArgumentError => err
          return nil
        end
      end

      def parse_float(text)
        begin
          return Float(text)
        rescue ArgumentError => err
          return nil
        end
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

end