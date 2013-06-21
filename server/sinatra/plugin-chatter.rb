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
require 'haml-util'
require 'napkin-plugins'
require 'napkin-tasks'
require 'napkin-handlers'

module Napkin
  module Plugins
    class Plugin_Chatter < PluginBase
      def get_segment
        return 'chatter'
      end

      def get_task_class_name
        return 'Task_Chatter'
      end
    end
  end

  module Tasks
    class Task_Chatter < TaskBase
      def init
        root_node_id = Neo.pin(:root)
        chatter_id = Neo.get_sub_id!('chatter', root_node_id)
        Neo.set_node_property('napkin.handlers.POST.class_name', 'Handler_Chatter_Post', chatter_id)
      end

      def todo?
        return false
      end

      def doit
      end
    end
  end

  module Handlers
    class Handler_Chatter_Post < HandlerBase
      def handle
        handle_time = Time.now

        param_format = get_param('format')
        return nil unless (param_format.nil? || param_format == 'napkin_kv')

        user_node_id = Neo.get_sub_id(@user, @segment_node_id)
        if (user_node_id.nil?) then
          user_node_id = Neo.get_sub_id!(@user, @segment_node_id)
          Neo.set_node_property('napkin.handlers.GET.class_name', 'Handler_Chatter_Get', user_node_id)
        end

        sub_list = Neo::SubList.new(user_node_id)
        chatter_node_id = sub_list.next_sub_id!

        Neo.set_node_property('chatter.handle_time~i', handle_time.to_i, chatter_node_id)

        body_text = get_body_text
        body_text.lines do |line|
          key, value = line.split('=', 2)
          key.strip! ; value.strip!
          next if KEY_MATCH.match(key).nil?
          if (KEY_TYPE_I_MATCH.match(key) != nil) then
            value = parse_int(value)
          elsif (KEY_TYPE_F_MATCH.match(key) != nil) then
            value = parse_float(value)
          end
          Neo.set_node_property(key, value, chatter_node_id) unless value.nil?
        end

        return "OK"
      end
    end

    class Handler_Chatter_Get < DefaultGetHandler
      def handle?
        return at_destination? || (remaining_segments == 1)
      end

      def handle
        return super if at_destination?

        sub_list = Neo::SubList.new(@segment_node_id)
        sub_index = get_segment(@segment_index+1)
        sub_node_id = sub_list.get_sub_id(sub_index)
        return super if sub_node_id.nil?

        param_key = get_param('key')

        if param_key.nil? then
          return Neo.get_node_properties_text(sub_node_id)
        end

        value = Neo.get_node_property(param_key, sub_node_id)
        return value.to_s
      end

      def handle_OLD
        time_now_i = Time.now.to_i

        user_segment = get_segment(@segment_index+1)
        user_node_id = Neo.get_sub_id(user_segment, @segment_node_id)

        return nil if user_node_id.nil?

        param_key = get_param('key')

        time_series = Neo.get_time_series(
        user_node_id, param_key,
        'chatter.handle_time~i', time_now_i,
        10, 600
        )

        @response.headers['Content-Type'] = 'text/html'
        haml_out = Haml.render_line_chart("#{user_segment} chatter", [param_key], time_series)
        return haml_out
      end
    end

  end
end