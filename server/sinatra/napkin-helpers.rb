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
require 'napkin-tasks'
require 'napkin-handlers'

module Napkin
  module Helpers
    #
    Neo = Napkin::Neo4jUtil
    #
    NodeId = {}

    def Helpers.init_neo4j()
      start_time = Time.now

      NodeId[:root] = Neo.get_root_node_id()
      NodeId[:napkin] = Neo.get_sub_id!('napkin', NodeId[:root])
      NodeId[:starts] = Neo.get_sub_id!('starts', NodeId[:napkin])
      NodeId[:start] = Neo.next_sub_id!(NodeId[:starts])

      Neo.set_property('napkin.starts.start_time', "#{start_time}", NodeId[:start])
      Neo.set_property('napkin.starts.start_time_i', start_time.to_i, NodeId[:start])

      start_count = Neo.get_property('napkin.sub_count', NodeId[:starts])
      puts "STARTS: #{start_count}"

      NodeId[:handles] = Neo.get_sub_id!('handles', NodeId[:napkin])
      NodeId[:pulses] = Neo.get_sub_id!('pulses', NodeId[:napkin])
      NodeId[:tasks] = Neo.get_sub_id!('tasks', NodeId[:napkin])
      Neo.set_property('napkin.handlers.POST', 'TaskPostHandler', NodeId[:tasks])

      NodeId[:plugins] = Neo.get_sub_id!('plugins', NodeId[:napkin])

      #TODO: plugin-specific init
      config_id = Neo.get_sub_id!('config', NodeId[:root] )
      Neo.set_property('napkin.handlers.POST', 'ConfigPostHandler', config_id)
    end

    def Helpers.start_pulse()
      pulse = Napkin::Tasks::Pulse.new(NodeId[:pulses], NodeId[:tasks])
      pulse.start()
    end

    def handle_request(path, request, user)
      begin
        handle_time = Time.now
        content_type 'text/plain'
        segments = path.split('/')

        handle_node_id = Neo.next_sub_id!(NodeId[:handles])
        Neo.set_property('napkin.handles.handle_time', handle_time.to_i, handle_node_id)

        segment_node_id = NodeId[:root]
        segments.each_with_index do |segment, i|
          segment_node_id = Neo.get_sub_id(segment, segment_node_id)
          break if segment_node_id.nil?

          handler_class = Handlers.get_handler_class(request.request_method, segment_node_id)
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
      return Neo.get_properties_text(NodeId[:root])
    end

    class Authenticator
      def check(username, password)
        return username == password
      end
    end
  end
end
