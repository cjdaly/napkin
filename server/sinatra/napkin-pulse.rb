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
require 'napkin-neo4j'
require 'napkin-handlers'
require 'napkin-tasks'

module Napkin
  module Pulse
    class Driver
      def initialize(napkin_driver)
        @napkin_driver = napkin_driver
        @plugin_registry = napkin_driver.plugin_registry
      end

      def neo
        return @plugin_registry.neo
      end

      def start()
        @finished = false
        @enabled = true
        @thread = Thread.new do
          begin
            puts "Pulse thread started..."
            start_node_id = neo.pin(:start)
            neo.set_node_property('napkin.pulses.first_pulse_time_i', Time.now.to_i, start_node_id)
            pulse_count = neo.increment_counter('napkin.pulses.pulse_count', start_node_id)
            puts "Pulse thread initialized (#{pulse_count})..."

            create_tasks()

            while (@enabled)
              sleep 5
              neo.set_node_property('napkin.pulses.last_pulse_time_i', Time.now.to_i, start_node_id)
              pulse_count = neo.increment_counter('napkin.pulses.pulse_count', start_node_id)
              puts "Pulse thread - new pulse (#{pulse_count})..."

              @tasks.each do |task|
                pulse_task(task)
              end
            end
            puts "Pulse thread stopped..."
          rescue StandardError => err
            puts "Error in Pulse thread: #{err}\n#{err.backtrace}"
          end
          @finished = true
        end
      end

      def stop()
        @enabled = false
        while(!@finished) do
          puts "Pulse driver - waiting for pulse thread to stop..."
          sleep 1
        end
        puts "Pulse driver - pulse thread stopped"

        @tasks.each do |task|
          begin
            puts "Pulse driver - finalizing task: #{task.class}"
            task.fini
            task.fini!
            puts "Pulse driver - finalized task: #{task.class}"
          rescue StandardError => err
            puts "Error finalizing task #{task.class}: #{err}\n#{err.backtrace}"
          end
        end
      end

      def create_tasks()
        @tasks = []
        plugins = @plugin_registry.get_plugins
        plugins.each do |plugin|
          plugin.get_task_classes.each do |task_class|
            begin
              @tasks << task_class.new(plugin)
            rescue StandardError => err
              puts "Error initializing task #{task_class}: #{err}\n#{err.backtrace}"
            end
          end
        end
      end

      def pulse_task(task)
        begin
          if (!task.init?) then
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
    end

  end
end