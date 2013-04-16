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

            puts "Pulse thread initialized..."
            while (@enabled)
              puts "Pulse thread looping..."
              task_node_ids = Neo4jUtil.get_sub_ids(@tasks_node_id)
              task_node_ids.each do |task_node_id|
                puts "Task: #{task_node_id}"
              end
              sleep 3
            end
            puts "Pulse thread stopped..."
          rescue StandardError => err
            puts "Error in Pulse thread: #{err}\n#{err.backtrace}"
          end
        end
      end

    end
  end

  module Handlers
    class TaskPostHandler < HandlerBase
      def handle
        param_sub = @query_hash['sub'].first
        # TODO: validate param_sub as good segment
        return nil if param_sub.to_s.empty?

        sub_node_id = Neo.get_sub_id!(param_sub, @segment_node_id)

        return "TaskPostHandler, param_sub: #{param_sub}"
      end
    end
  end
end