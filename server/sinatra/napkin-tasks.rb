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
    TaskData = {}

    class TaskBase
      def initialize(task_node_id, pulse_node_id, task_data, task_segment)
        @task_node_id = task_node_id
        @pulse_node_id = pulse_node_id
        @task_data = task_data
        @task_segment = task_segment
      end

      def todo?
        return false
      end

      def doit!
      end
    end

    class TestTask < TaskBase
      def todo?
        if (@task_data['foo'].nil?) then
          @task_data['foo'] = 0
        end
        @task_data['foo'] += 1

        puts "HELLO??? #{@task_data['foo']}"

        if (@task_data['foo'] > 5) then
          return true
        else
          return super
        end
      end

      def doit!
        @task_data['foo'] = 0
        puts "HELLO!!!"
      end
    end

    class Pulse
      def initialize(pulses_node_id, tasks_node_id)
        @pulses_node_id = pulses_node_id
        @tasks_node_id = tasks_node_id
      end

      def start()
        @enabled = true
        @thread = Thread.new do
          begin
            puts "Pulse thread started..."

            pulse_node_id = Neo.next_sub_id!(@pulses_node_id)
            Neo.set_property('napkin.pulse.start_time_i', Time.now.to_i, pulse_node_id)

            end_of_pulse = false
            pulse_skip_count = 0

            puts "Pulse thread initialized..."
            while (@enabled)
              puts "Pulse thread looping..."
              task_node_ids = Neo4jUtil.get_sub_ids(@tasks_node_id)
              task_node_ids.each do |task_node_id|
                task = get_task_instance(task_node_id, pulse_node_id)
                end_of_pulse ||= pulse_task(task) unless task.nil?
              end
              pulse_skip_count += 1
              sleep 2
              if (end_of_pulse) then
                puts "Pulse thread - new pulse..."
                Neo.set_property('napkin.pulse.pulse_skip_count', pulse_skip_count, pulse_node_id)
                Neo.set_property('napkin.pulse.end_time_i', Time.now.to_i, pulse_node_id)
                pulse_node_id = Neo.next_sub_id!(@pulses_node_id)
                Neo.set_property('napkin.pulse.start_time_i', Time.now.to_i, pulse_node_id)
                end_of_pulse = false
                pulse_skip_count = 0
              end
              sleep 1
            end
            puts "Pulse thread stopped..."
          rescue StandardError => err
            puts "Error in Pulse thread: #{err}\n#{err.backtrace}"
          end
        end
      end

      def pulse_task(task)
        begin
          if (task.todo?) then
            task.doit!
            return true
          end
        rescue StandardError => err
          puts "Error in pulse_task: #{err}\n#{err.backtrace}"
        end
        return false
      end

      def get_task_instance(task_node_id, pulse_node_id)
        task_class_name = Neo.get_property("napkin.tasks.task_class_name", task_node_id)
        return nil if task_class_name.nil?

        begin
          task_class = Napkin::Tasks.const_get(task_class_name)
        rescue StandardError => err
          task_class = nil
        end

        return nil if task_class.nil?

        task_segment = Neo.get_property('napkin.segment', task_node_id)
        if (TaskData[task_segment].nil?) then
          TaskData[task_segment] = {}
        end
        task_data = TaskData[task_segment]

        task_instance = task_class.new(task_node_id, pulse_node_id, task_data, task_segment)
        return task_instance
      end

    end
  end

  module Handlers
    class TaskPostHandler < HandlerBase
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