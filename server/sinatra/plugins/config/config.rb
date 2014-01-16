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
  class Config < PluginBase
    def init
      config_node_id = init_service_segment

      register_handler('get', Get_Handler)
      register_handler('put', Put_Handler)

      register_handler('post', Post_Handler)
      attach_handler('post', 'POST', config_node_id)
    end

    class Get_Handler < Napkin::Handlers::DefaultGetHandler
      def kramdown_features(node_id)
        return "\n    Special features for node #{node_id}\n"
      end
    end

    class Post_Handler < Napkin::Handlers::HandlerBase
      def handle
        param_sub = get_param('sub')
        return nil if param_sub.nil?

        sub_node_id = neo.get_sub_id!(param_sub, @segment_node_id)
        get_plugin.attach_handler('post', 'POST', sub_node_id)
        get_plugin.attach_handler('put', 'PUT', sub_node_id)
        get_plugin.attach_handler('get', 'GET', sub_node_id)

        return "OK"
      end
    end

    class Put_Handler < Napkin::Handlers::HandlerBase
      def handle
        param_key = get_param('key')
        return nil if param_key.nil?

        value = get_body_text

        if (KEY_TYPE_I_MATCH.match(param_key) != nil) then
          value = parse_int(value)
        elsif (KEY_TYPE_F_MATCH.match(param_key) != nil) then
          value = parse_float(value)
        end

        neo.set_node_property(param_key, value, @segment_node_id) unless value.nil?

        return "OK"
      end
    end

  end
end
