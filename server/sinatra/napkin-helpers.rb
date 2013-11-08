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
require 'napkin-plugins'
require 'napkin-tasks'
require 'napkin-pulse'
require 'napkin-handlers'

module Napkin
  NAPKIN_VERSION = "0.4.1" # 0.4.x for adopting Neo4j 2.0
  #
  module Helpers
    #
    Config = {}
    #
    Neo = Napkin::Neo4jUtil

    #
    def Helpers.init_system_config()
      system_config_file = ARGV[0].to_s
      raise "Specify system configuration file!" unless File.exist?(system_config_file)
      system_config_hash = JSON.parse(File.read(system_config_file))
      Config[:system] = system_config_hash
      puts "Napkin system name: #{Config[:system]['napkin.config.system_name']}"
    end

    def Helpers.init_neo4j()
      start_time = Time.now

      Neo.create_napkin_index()
      Neo.create_napkin_root_constraint()

      # create top-level nodes
      Neo.pin!(:root, Neo.get_root_node_id())
      Neo.pin!(:napkin, Neo.get_sub_id!('napkin', Neo.pin(:root)))

      # Napkin version
      version = Neo.get_node_property('napkin.VERSION', Neo.pin(:napkin))
      if (version.to_s == "") then
        Neo.set_node_property('napkin.VERSION', NAPKIN_VERSION, Neo.pin(:napkin))
      elsif (version != NAPKIN_VERSION)
        raise "Helpers.init_neo4j - database/runtime version mismatch! (#{version}/#{NAPKIN_VERSION})"
      end
      puts "Napkin version: #{NAPKIN_VERSION}"

      # system name
      system_name = Config[:system]['napkin.config.system_name']
      Neo.set_node_property('napkin.config.system_name', system_name, Neo.pin(:napkin))

      # Neo4j database path
      neo4j_db_path = Config[:system]['napkin.config.Neo4J_db_path']
      Neo.set_node_property('napkin.config.Neo4J_db_path', neo4j_db_path, Neo.pin(:napkin))

      # starts
      Neo.pin!(:starts, Neo.get_sub_id!('starts', Neo.pin(:napkin)))
      starts_sub_list = Neo::SubList.new(Neo.pin(:starts))
      Neo.pin!(:start, starts_sub_list.next_sub_id!)

      Neo.set_node_property('napkin.starts.start_time', "#{start_time}", Neo.pin(:start))
      Neo.set_node_property('napkin.starts.start_time_i', start_time.to_i, Neo.pin(:start))

      start_count = Neo.get_node_property('napkin.sublist_count', Neo.pin(:starts))
      puts "Napkin system starts: #{start_count}"
    end

    def Helpers.init_plugins()
      plugins_path = Config[:system]['napkin.config.plugins_path'] || 'plugins'
      system_name = Config[:system]['napkin.config.system_name']
      system_plugins_path = "systems/#{system_name}/plugins"
      plugin_registry = Napkin::Plugins::PluginRegistry.new(plugins_path, system_plugins_path)
      Config[:registry] = plugin_registry
    end

    def Helpers.start_pulse()
      plugin_registry = Config[:registry]
      pulse = Napkin::Pulse::Driver.new(plugin_registry)
      pulse.start()
    end

    def handle_request(path, user)
      begin
        handle_time = Time.now
        content_type 'text/plain'
        segments = path.split('/')

        segment_node_id = Neo.pin(:root)
        if (segments.length == 0) then
          handler = instantiate_handler(segment_node_id, segments, -1, user)
          if (handler.handle?) then
            result = handler.handle
            return result if !result.nil?
          end
        else
          segments.each_with_index do |segment, i|
            segment_node_id = Neo.get_sub_id(segment, segment_node_id)
            break if segment_node_id.nil?

            handler = instantiate_handler(segment_node_id, segments, i, user)
            if (handler.handle?) then
              result = handler.handle
              return result if !result.nil?
            end
          end
        end

      rescue StandardError => err
        puts "Error in handle_request: #{err}\n#{err.backtrace}"
      end

      # TODO: some kind of 404
      return Neo.get_node_properties_text(Neo.pin(:root))
    end

    def instantiate_handler(segment_node_id, segments, segment_index, user)
      handler_class, handler_plugin = get_handler_class_and_plugin(request.request_method, segment_node_id)
      if (!handler_class.nil?) then
        return handler_class.new(segment_node_id, request, response, segments, segment_index, user, handler_plugin)
      end

      return Handlers::NeverHandler.new(segment_node_id, request, response, segments, segment_index, user)
    end

    def get_handler_class_and_plugin(method, segment_node_id)
      handler_id = Neo.get_node_property("napkin.handlers.#{method}", segment_node_id)
      if ((handler_id.nil?) && (method == "GET")) then
        return Handlers::DefaultGetHandler, nil
      end

      return nil, nil if handler_id.nil?
      return nil, nil unless handler_id.include?('~')
      handler_id_prefix,handler_id_suffix = handler_id.split('~', 2)

      plugin_registry = Config[:registry]
      return nil, nil if plugin_registry.nil?

      handler_plugin = plugin_registry.get_plugin(handler_id_prefix)
      return nil, nil if handler_plugin.nil?

      handler_class = handler_plugin.get_handler_class(handler_id_suffix)
      return handler_class, handler_plugin
    end

    class Authenticator
      def check(username, password)
        return username == password
      end
    end
  end
end
