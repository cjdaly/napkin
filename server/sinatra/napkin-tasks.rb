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

module Napkin
  module Tasks
    #
    Neo = Napkin::Neo4jUtil
    #
    class Pulse
      def start
        @enabled = true
        @thread = Thread.new do
          begin
            puts "Pulse thread started..."

            init_tasks

            puts "Pulse thread initialized..."
            while (next_cycle)
              nn = Napkin::NodeUtil::NodeNav.new
              nn.go_sub_path!('napkin/cycles', true)
              cycle_count = nn['cycle_count']
              puts "Pulse thread - cycle: #{cycle_count}"

              pre_cycle_delay_seconds = nn.get_or_init('pre_cycle_delay_seconds', 5)
              sleep pre_cycle_delay_seconds
              if (@enabled)
                process_tasks
                puts "Pulse thread refreshed..."
              else
                puts "Pulse thread disabled..."
              end

              post_cycle_delay_seconds = nn.get_or_init('post_cycle_delay_seconds', 1)
              sleep post_cycle_delay_seconds
            end
            puts "Pulse thread stopped..."
          rescue StandardError => err
            puts "Error in Pulse thread: #{err}\n#{err.backtrace}"
          end
        end
      end

      def next_cycle
        cycle_start_time = Time.now
      end

      def init_tasks

      end
    end
  end
end