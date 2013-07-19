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
require 'cgi'
require 'neo4j-util'
require 'haml-util'
require 'kramdown-util'

module Napkin
  module Handlers
    #
    Neo = Napkin::Neo4jUtil
    Haml = Napkin::HamlUtil
    Kram = Napkin::KramdownUtil
    #
    KEY_TYPE_I_MATCH = /.+~i$/
    KEY_TYPE_F_MATCH = /.+~f$/
    #
    class HandlerBase
      def initialize(segment_node_id, request, response, segments, segment_index, user)
        @segment_node_id = segment_node_id
        @request = request
        @response = response
        @segments = segments
        @segment_index = segment_index
        @user = user
        @query_hash = CGI.parse(@request.query_string)
      end

      def remaining_segments
        return @segments.length() - (@segment_index + 1)
      end

      def at_destination?
        return remaining_segments == 0
      end

      def get_segment(index = @segment_index)
        return nil if ((index < 0) || (index >= @segments.length))
        return @segments[index]
      end

      def get_path(start_index=0, end_index=@segment_index)
        path = ""
        index = start_index
        while index <= end_index do
          path << "/"
          path << @segments[index]
          index += 1
        end
        return path
      end

      def get_param(key, validate_as_segment = true)
        param = @query_hash[key].first
        return nil if param.to_s.empty?
        if (validate_as_segment) then
          return nil unless Neo.valid_segment?(param)
        end
        return param
      end

      def get_body_text
        @request.body.rewind
        return @request.body.read
      end

      def parse_int(text)
        return nil if text.nil?
        begin
          return Integer(text)
        rescue ArgumentError => err
          return nil
        end
      end

      def parse_float(text)
        return nil if text.nil?
        begin
          return Float(text)
        rescue ArgumentError => err
          return nil
        end
      end

      #
      # override below in subclass
      #

      def handle?
        return at_destination?
      end

      def handle
        return nil
      end

    end

    class DefaultGetHandler < HandlerBase
      def handle
        param_key = get_param('key')
        if (param_key.nil?) then
          kramdown_text = prepare_kramdown
          return kramdown_to_html(kramdown_text)
        else
          return handle_property_get(param_key, @segment_node_id)
        end
      end

      def handle_property_get(param_key, node_id)
        value = Neo.get_node_property(param_key, node_id)
        return value.to_s
      end

      def prepare_kramdown(segment_node_id=@segment_node_id, segment_index=@segment_index)
        kramdown_text = kramdown_preamble(segment_node_id, segment_index)
        kramdown_text << kramdown_subordinates(segment_node_id, segment_index)
        kramdown_text << kramdown_properties(segment_node_id, segment_index)
        return kramdown_text
      end

      def kramdown_preamble(segment_node_id, segment_index)
        segment = get_segment(segment_index)
        path = get_path(0, segment_index)
        sup_segment = get_segment(segment_index-1) || "nil"
        sup_path = get_path(0, segment_index-1)

        kramdown_text = "
# #{segment}

| *Path* | #{path}
| *Node ID* | #{segment_node_id}
| *Superior* | [#{sup_segment}](#{sup_path})
"
        return kramdown_text
      end

      def kramdown_subordinates(segment_node_id, segment_index)
        return "| *Subordinates* | ???\n"
      end

      def kramdown_subordinates_sublist(segment_node_id, segment_index)
        sub_list = Neo::SubList.new(segment_node_id)
        sublist_count = sub_list.get_count

        kramdown_text = "| *Subordinates* | *index*\n"
        sub_offset = 0
        while (sub_offset < 8)
          sub_index = sublist_count-sub_offset
          if (sub_index > 0)
            kramdown_text << "| | [#{sub_index}](#{get_path}/#{sub_index})\n"
          end
          sub_offset += 1
        end

        return kramdown_text
      end

      def kramdown_properties(segment_node_id, segment_index)
        kramdown_text = "| *Properties* | *key* | *type* | *value*\n"
        property_hash = Neo.get_node_properties(segment_node_id)
        property_hash.each do |key, value|
          kramdown_text << "| | #{key} | #{value.class} | #{value}\n"
        end
        return kramdown_text
      end

      def kramdown_to_html(kramdown_text)
        @response.headers['Content-Type'] = 'text/html'

        html_text = Kram.default_node_get_html(kramdown_text, get_segment)
        return html_text
      end
    end

    class SubListGetHandler < DefaultGetHandler
      def handle?
        return at_destination? || (remaining_segments == 1)
      end

      def handle
        return super if at_destination?

        sub_segment = get_segment(@segment_index+1)
        return handle_special_segment(sub_segment) if parse_int(sub_segment).nil?

        sub_list = Neo::SubList.new(@segment_node_id)
        sub_node_id = sub_list.get_sub_id(sub_segment)
        return super if sub_node_id.nil?

        param_key = get_param('key')
        return handle_property_get(param_key, sub_node_id) unless param_key.nil?

        kramdown_text = prepare_kramdown(sub_node_id, @segment_index+1)
        return kramdown_to_html(kramdown_text)
      end

      def handle_special_segment(segment)
        case segment
        when 'charts'
          return "..."
        else
          return nil
        end
      end

      def kramdown_subordinates(segment_node_id, segment_index)
        return super unless at_destination?
        return kramdown_subordinates_sublist(segment_node_id, segment_index)
      end
    end

  end
end

