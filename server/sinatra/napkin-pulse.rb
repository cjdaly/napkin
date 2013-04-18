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
require 'napkin-tasks'

module Napkin
  module Pulse
    #
    Neo = Napkin::Neo4jUtil
    #
    TaskData = {}

    class Driver
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
              task_node_ids = Neo.get_sub_ids(@tasks_node_id)
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
          if (task.init?) then
            task.init
            task.init!
            return true
          elsif (task.todo?)
            task.doit
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
end