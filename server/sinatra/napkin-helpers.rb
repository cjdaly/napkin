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
require 'napkin-core'

module Napkin
  module Helpers
    #
    Napkin_Driver = []
    #
    def Helpers.init_core_driver()
      # initialize system config
      system_config_file = ARGV[0].to_s
      raise "Specify system configuration file!" unless File.exist?(system_config_file)
      system_config_hash = JSON.parse(File.read(system_config_file))
      puts "Napkin system name: #{system_config_hash['napkin.config.system_name']}"

      # start driver
      napkin_driver = Napkin::Core::Driver.new(system_config_hash)
      Napkin_Driver << napkin_driver
      napkin_driver.start()
    end

    def handle_request(path, user)
      begin
        handle_time = Time.now
        content_type 'text/plain'

        napkin_driver = Napkin_Driver[0]
        if (!napkin_driver.running?) then
          status 503
          return "Napkin service not available!"
        end

        neo = napkin_driver.neo4j_connector.neo

        segments = path.split('/')
        segment_node_id = neo.pin(:root)
        if (segments.length == 0) then
          handler = instantiate_handler(neo, segment_node_id, segments, -1, user)
          if (!handler.nil? && handler.handle?) then
            result = handler.handle
            return result if !result.nil?
          end
        else
          segments.each_with_index do |segment, i|
            segment_node_id = neo.get_sub_id(segment, segment_node_id)
            break if segment_node_id.nil?

            handler = instantiate_handler(neo, segment_node_id, segments, i, user)
            if (!handler.nil? && handler.handle?) then
              result = handler.handle
              return result if !result.nil?
            end
          end
        end

      rescue StandardError => err
        puts "Error in handle_request: #{err}\n#{err.backtrace}"
      end

      return "No handler found in handle_request."
    end

    def instantiate_handler(neo, segment_node_id, segments, segment_index, user)
      handler_class, handler_plugin = get_handler_class_and_plugin(neo, request.request_method, segment_node_id)
      if (!handler_class.nil?) then
        return handler_class.new(neo, segment_node_id, request, response, segments, segment_index, user, handler_plugin)
      end
      return nil
    end

    def get_handler_class_and_plugin(neo, method, segment_node_id)
      handler_id = neo.get_node_property("napkin.handlers.#{method}", segment_node_id)
      if ((handler_id.nil?) && (method == "GET")) then
        return Handlers::DefaultGetHandler, nil
      end

      return nil, nil if handler_id.nil?
      return nil, nil unless handler_id.include?('~')
      handler_id_prefix,handler_id_suffix = handler_id.split('~', 2)

      napkin_driver = Napkin_Driver[0]
      plugin_registry = napkin_driver.plugin_registry
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
