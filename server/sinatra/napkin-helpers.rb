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
  NAPKIN_VERSION = "0.2"
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

      # create top-level nodes
      Neo.pin!(:root, Neo.get_root_node_id())
      Neo.pin!(:napkin, Neo.get_sub_id!('napkin', Neo.pin(:root)))

      # Napkin version
      version = Neo.get_node_property('napkin.VERSION', Neo.pin(:napkin))
      if (version.to_s == "") then
        Neo.set_node_property('napkin.VERSION', NAPKIN_VERSION, Neo.pin(:napkin))
      elsif (version != NAPKIN_VERSION)
        raise "Helpers.init_neo4j - database version mismatch!"
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
      Neo.pin!(:start, Neo.next_sub_id!(Neo.pin(:starts)))

      Neo.set_node_property('napkin.starts.start_time', "#{start_time}", Neo.pin(:start))
      Neo.set_node_property('napkin.starts.start_time_i', start_time.to_i, Neo.pin(:start))

      start_count = Neo.get_node_property('napkin.sub_count', Neo.pin(:starts))
      puts "Napkin system starts: #{start_count}"

      # tasks
      Neo.pin!(:tasks, Neo.get_sub_id!('tasks', Neo.pin(:napkin)))
    end

    def Helpers.init_plugins()
      Napkin::Plugins.init()
    end

    def Helpers.start_pulse()
      pulse = Napkin::Pulse::Driver.new
      pulse.start()
    end

    def handle_request(path, user)
      begin
        handle_time = Time.now
        content_type 'text/plain'
        segments = path.split('/')

        segment_node_id = Neo.pin(:root)
        segments.each_with_index do |segment, i|
          segment_node_id = Neo.get_sub_id(segment, segment_node_id)
          break if segment_node_id.nil?

          handler_class = get_handler_class(request.request_method, segment_node_id)
          if (!handler_class.nil?) then
            handler = handler_class.new(segment_node_id, request, response, segments, i, user)
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

    def get_handler_class(method, segment_node_id)
      handler_class_name = Neo.get_node_property("napkin.handlers.#{method}.class_name", segment_node_id)
      if (handler_class_name.nil?) then
        return (method == "GET") ? Handlers::DefaultGetHandler : nil
      end

      begin
        handler_class = Napkin::Handlers.const_get(handler_class_name)
      rescue StandardError => err
        handler_class = nil
      end

      if (handler_class.nil?) then
        return (method == "GET") ? Handlers::DefaultGetHandler : nil
      end

      return handler_class
    end

    class Authenticator
      def check(username, password)
        return username == password
      end
    end
  end
end
