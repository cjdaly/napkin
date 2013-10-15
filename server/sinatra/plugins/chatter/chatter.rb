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

module Napkin::Plugins
  class Chatter < PluginBase
    def init
      chatter_node_id = init_service_segment

      register_handler('post', Post_Handler)
      attach_handler('post', 'POST', chatter_node_id)
    end

    class Post_Handler < Napkin::Handlers::HandlerBase
      def handle
        handle_time = Time.now

        param_format = get_param('format')
        return nil unless (param_format.nil? || param_format == 'napkin_kv')

        user_node_id = Neo.get_sub_id(@user, @segment_node_id)
        if (user_node_id.nil?) then
          user_node_id = Neo.get_sub_id!(@user, @segment_node_id)
          get_plugin.attach_handler('get', 'GET', user_node_id)
        end

        sub_list = Neo::SubList.new(user_node_id)
        chatter_node_id = sub_list.next_sub_id!

        Neo.set_node_property('chatter.handle_time~i', handle_time.to_i, chatter_node_id)

        body_text = get_body_text
        body_text.lines do |line|
          key, value = line.split('=', 2)
          key.strip! ; value.strip!
          next unless Neo.valid_segment?(key)
          if (KEY_TYPE_I_MATCH.match(key) != nil) then
            value = parse_int(value)
          elsif (KEY_TYPE_F_MATCH.match(key) != nil) then
            value = parse_float(value)
          end
          Neo.set_node_property(key, value, chatter_node_id) unless value.nil?
        end

        plugin_times = get_plugin('times')
        minute_node_id = plugin_times.get_nearest_minute_node_id!(handle_time)
        ref_id = Neo.set_ref!(chatter_node_id, minute_node_id)
        Neo.set_ref_property('times.source', "chatter.#{@user}", ref_id)

        return "OK"
      end
    end

    class Get_Handler < Napkin::Handlers::SubListGetHandler
      def kramdown_features(node_id)
        return super unless at_destination?

        sub_list = Neo::SubList.new(node_id)
        sublist_count = sub_list.get_count
        last_sub_id = sub_list.get_sub_id(sublist_count)

        return super if last_sub_id.nil?

        kramdown_text ="\n###Features\n\n"
        kramdown_text << "| *name*\n"
        property_hash = Neo.get_node_properties(last_sub_id)
        property_hash.each do |key, value|
          if (value.is_a? Numeric) then
            kramdown_text << "| chart #{key} "
            kramdown_text << "| [1 min](#{get_chart_url(1, key)}) "
            kramdown_text << "| [5 min](#{get_chart_url(5, key)}) "
            kramdown_text << "| [10 min](#{get_chart_url(10, key)}) "
            kramdown_text << "| [15 min](#{get_chart_url(15, key)}) "
            kramdown_text << "| [30 min](#{get_chart_url(30, key)}) "
            kramdown_text << "| [60 min](#{get_chart_url(60, key)})\n"
          end
        end
        return kramdown_text
      end

      def get_chart_url(skip, data_key)
        return "#{get_path}/charts?offset=0&samples=120&skip=#{skip}&source=chatter.#{get_segment}&data_key=#{data_key}&time_i_key=chatter.handle_time~i"
      end
    end
  end
end
