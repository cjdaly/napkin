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
require 'napkin-plugins'
require 'napkin-tasks'
require 'napkin-pulse'
require 'napkin-handlers'

module Napkin
  module Helpers
    #
    Neo = Napkin::Neo4jUtil
    #
    def Helpers.init_neo4j()
      start_time = Time.now

      Neo.pin!(:root, Neo.get_root_node_id())
      Neo.pin!(:napkin, Neo.get_sub_id!('napkin', Neo.pin(:root)))
      Neo.pin!(:starts, Neo.get_sub_id!('starts', Neo.pin(:napkin)))
      Neo.pin!(:start, Neo.next_sub_id!(Neo.pin(:starts)))

      Neo.set_node_property('napkin.starts.start_time', "#{start_time}", Neo.pin(:start))
      Neo.set_node_property('napkin.starts.start_time_i', start_time.to_i, Neo.pin(:start))

      start_count = Neo.get_node_property('napkin.sub_count', Neo.pin(:starts))
      puts "STARTS: #{start_count}"

      Neo.pin!(:tasks, Neo.get_sub_id!('tasks', Neo.pin(:napkin)))
      Neo.pin!(:pulses, Neo.get_sub_id!('pulses', Neo.pin(:napkin)))
      Neo.pin!(:handles, Neo.get_sub_id!('handles', Neo.pin(:napkin)))
    end

    def Helpers.start_pulse()
      pulse = Napkin::Pulse::Driver.new(Neo.pin(:pulses), Neo.pin(:tasks))
      pulse.start()
    end

    def Helpers.init_plugins()
      Napkin::Plugins.init()
    end

    def handle_request(path, request, user)
      begin
        handle_time = Time.now
        content_type 'text/plain'
        segments = path.split('/')

        handle_node_id = Neo.next_sub_id!(Neo.pin(:handles))
        Neo.set_node_property('napkin.handles.handle_time', handle_time.to_i, handle_node_id)

        segment_node_id = Neo.pin(:root)
        segments.each_with_index do |segment, i|
          segment_node_id = Neo.get_sub_id(segment, segment_node_id)
          break if segment_node_id.nil?

          handler_class = get_handler_class(request.request_method, segment_node_id)
          if (!handler_class.nil?) then
            handler = handler_class.new(segment_node_id, handle_node_id, request, segments, i, user)
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
