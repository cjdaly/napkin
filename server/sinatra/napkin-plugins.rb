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
require 'json'
require 'neo4j-util'
require 'napkin-tasks'

module Napkin
  module Plugins
    #
    Neo = Napkin::Neo4jUtil
    #
    class PluginBase
      def initialize(config_hash, plugin_registry)
        @config = config_hash
        @plugin_registry = plugin_registry
        @handlers = {}
        @tasks = {}
      end

      def get_plugin(id)
        return self if id.nil?
        return @plugin_registry.get_plugin(id)
      end

      #
      # handlers
      #

      def register_handler(handler_name, handler_class)
        @handlers[handler_name] = handler_class
      end

      def attach_handler(handler_name, method, node_id)
        Neo.set_node_property("napkin.handlers.#{method}", "#{get_id}~#{handler_name}", node_id)
      end

      def get_handler_class(handler_name)
        return @handlers[handler_name]
      end

      #
      # tasks
      #

      def register_task(task_name, task_class)
        @tasks[task_name] = task_class
      end

      def get_task_classes()
        return @tasks.values
      end

      #
      # override below in subclass
      #
      def get_id
        default_id = self.class.to_s.split('::').last
        default_id[0] = default_id[0].downcase
        return default_id
      end

      def get_segment
        return get_id
      end

      def init
      end

      def init_service_segment(sup_node_id = nil)
        sup_node_id = Neo.pin(:root) if sup_node_id.nil?
        service_node_id = Neo.get_sub_id!(get_segment, sup_node_id)
        return service_node_id
      end
    end

    class PluginRegistry
      def initialize(plugins_path, system_plugins_path)
        @plugins = {}

        init_plugins_dir(plugins_path)
        init_plugins_dir(system_plugins_path)
      end

      def init_plugins_dir(plugins_path)
        return if plugins_path.nil?
        return unless Dir.exists?(plugins_path)

        Dir.foreach(plugins_path) do |plugin_id|
          next if (plugin_id == '.') or (plugin_id == '..')
          plugin_dir = "#{plugins_path}/#{plugin_id}"
          next unless File.directory?(plugin_dir)

          plugin = init_plugin(plugin_id, plugin_dir)
          if (!plugin.nil?) then
            @plugins[plugin_id] = plugin
          end
        end
      end

      def get_plugin(plugin_id)
        return @plugins[plugin_id]
      end

      def get_plugins()
        return @plugins.values
      end

      def create_tasks()
        tasks = []
        @plugins.values.each do |plugin|
          plugin.get_task_classes.each do |task_class|
            begin
              tasks << task_class.new(plugin)
            rescue StandardError => err
              puts "Error initializing task #{task_class}: #{err}\n#{err.backtrace}"
            end
          end
        end
        return tasks
      end

      def init_plugin(plugin_id, plugin_dir)
        plugin_class_file = "#{plugin_dir}/#{plugin_id}.rb"
        return nil unless File.exists?(plugin_class_file)
        puts "Initializing plugin: #{plugin_id}"

        begin
          plugin_config_file = "#{plugin_dir}/config.json"
          plugin_config_hash = {}
          if (File.exists?(plugin_config_file)) then
            plugin_config_hash = JSON.parse(File.read(plugin_config_file))
          end

          require(plugin_class_file)
          plugin_class =  get_plugin_class(plugin_id)
          return nil if plugin_class.nil?

          plugin = plugin_class.new(plugin_config_hash, self)
          plugin.init
          return plugin
        rescue StandardError => err
          puts "Error initializing plugin #{plugin_id}: #{err}\n#{err.backtrace}"
          return nil
        end
      end

      def get_plugin_class(plugin_id)
        plugin_class_name = plugin_id.capitalize
        plugin_class = nil
        begin
          plugin_class = Napkin::Plugins.const_get(plugin_class_name, false)
        rescue NameError => err
          #
        end
        return plugin_class
      end
    end

  end
end