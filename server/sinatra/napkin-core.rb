####
# Copyright (c) 2014 Chris J Daly (github user cjdaly)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   cjdaly - initial API and implementation
####

require 'napkin-neo4j'
require 'napkin-plugins'
require 'napkin-pulse'

module Napkin
  module Core
    class Driver
      def initialize(system_config)
        @system_config = system_config

        # TODO: @mode usage not thread safe
        @mode = :init

        @neo4j_connector = nil
        @plugin_registry = nil
        @pulse_driver = nil
      end

      def system_config
        return @system_config
      end

      def neo4j_connector
        return @neo4j_connector
      end

      def plugin_registry
        return @plugin_registry
      end

      def pulse_driver
        return @pulse_driver
      end

      def start()
        @continue = true
        @thread = Thread.new do
          begin
            puts "Napkin driver thread started..."

            while (@continue)
              case @mode
              when :init
                @mode = :start
                puts "Napkin driver thread initialized..."
              when :start
                puts "Napkin driver thread starting..."
                startup_napkin
                @mode = :run
                puts "Napkin driver thread started"
              when :run
                # puts "Napkin driver thread running..."
              when :restart
                puts "Napkin driver thread restarting..."
                shutdown_napkin
                @mode = :start
              when :stop
                puts "Napkin driver thread stopping..."
                shutdown_napkin
                @continue = false
              else
                puts "Napkin driver thread - unknown mode: #{@mode}"
              end

              sleep 2
              # puts "Napkin driver thread looping..."
            end
            puts "Napkin driver thread stopped..."
          rescue StandardError => err
            puts "Error in Napkin driver thread: #{err}\n#{err.backtrace}"
          end
        end
      end

      def startup_napkin
        # neo4j
        puts "Napkin driver thread - initializing Neo4j connection"
        @neo4j_connector = Napkin::Neo4j::Connector.new(self)
        @neo4j_connector.init_neo()

        # plugins
        puts "Napkin driver thread - initializing plugin registry"
        plugins_path = @system_config['napkin.config.plugins_path'] || 'plugins'
        system_name = @system_config['napkin.config.system_name']
        system_plugins_path = "systems/#{system_name}/plugins"
        @plugin_registry = Napkin::Plugins::PluginRegistry.new(self, plugins_path, system_plugins_path)

        # pulse
        puts "Napkin driver thread - starting pulse"
        @pulse_driver = Napkin::Pulse::Driver.new(self)
        @pulse_driver.start()
      end

      def shutdown_napkin
        # pulse
        puts "Napkin driver thread - stopping pulse"
        @pulse_driver.stop

        # plugins
        puts "Napkin driver thread - finalizing plugin registry"
        @plugin_registry.fini_plugins

        # neo4j
        puts "Napkin driver thread - disconnect Neo4j"
        @neo4j_connector.disconnect!

        @neo4j_connector = nil
        @plugin_registry = nil
        @pulse_driver = nil
      end

      def running?
        return @mode == :run
      end

      def restart(message)
        raise "Napkin driver thread - restart only when running!" unless @mode == :run
        puts "Napkin driver thread - restart: #{message}"
        @mode = :restart
      end

      def stop(message)
        raise "Napkin driver thread - stop only when running!" unless @mode == :run
        puts "Napkin driver thread - stop: #{message}"
        @mode = :stop
      end

    end
  end
end
