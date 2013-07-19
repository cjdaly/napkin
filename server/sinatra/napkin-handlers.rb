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
        kramdown_text << kramdown_specials(segment_node_id, segment_index)
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

      def kramdown_specials(segment_node_id, segment_index)
        return "| *Specials* | ???\n"
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
          if (get_param('data_key').nil?) then
            return handle_chart_multi
          else
            return handle_chart_single
          end
        end
        return nil
      end

      def handle_chart_single()
        handle_time = Time.now
        minute_time = round_to_minute_helper(handle_time)
        minute_time_i = minute_time.to_i

        offset = parse_int(get_param('offset')) || 0
        minute_time_i -= (offset * 60)

        samples = parse_int(get_param('samples')) || 15
        skip = parse_int(get_param('skip')) || 1

        param_source = get_param('source')
        param_time_i_key = get_param('time_i_key')
        param_data_key = get_param('data_key')

        if (param_source.nil? || param_time_i_key.nil?) then
          return nil
        end
        keys = [param_time_i_key, param_data_key]

        minute_time_i = minute_time_i - (60 * samples * skip)
        time_series = []
        for i in 1..samples
          minute_time_i += (60 * skip)
          minute_time = Time.at(minute_time_i)

          data = get_nearest_minute_data_helper(minute_time, param_source, keys, function="", param_time_i_key)
          data.each do |time_value|
            time_i = time_value[0]
            time = Time.at(time_i)
            time_javascript = "new Date(#{time.year},#{time.month-1},#{time.day},#{time.hour},#{time.min},#{time.sec})"
            value = time_value[1]
            time_series << [time_javascript, value]
          end
        end

        @response.headers['Content-Type'] = 'text/html'
        value_labels = [keys[1]]
        haml_out = Haml.render_line_chart(param_source, value_labels, time_series)
        return haml_out
      end

      def handle_chart_multi()
        handle_time = Time.now
        minute_time = round_to_minute_helper(handle_time)
        minute_time_i = minute_time.to_i

        offset = parse_int(get_param('offset')) || 0
        minute_time_i -= (offset * 60)

        samples = parse_int(get_param('samples')) || 15
        skip = parse_int(get_param('skip')) || 1

        param_source = get_param('source')
        param_keys = get_param('keys', false)

        keys = []
        param_keys.split(',').each do |key|
          if (Neo.valid_segment?(key)) then
            keys << key
          end
        end

        minute_time_i = minute_time_i - (60 * samples * skip)
        time_series = []
        for i in 1..samples
          minute_time_i += (60 * skip)
          minute_time = Time.at(minute_time_i)
          row = ["new Date(#{minute_time.year},#{minute_time.month-1},#{minute_time.day},#{minute_time.hour},#{minute_time.min})"]

          data = get_nearest_minute_data_helper(minute_time, param_source, keys)
          if (data[0].nil?) then
            keys.each do |key|
              row << nil
            end
          else
            data[0].each do |value|
              row << value
            end
          end

          time_series << row
        end

        @response.headers['Content-Type'] = 'text/html'
        value_labels = keys
        haml_out = Haml.render_line_chart(param_source, value_labels, time_series)
        return haml_out
      end

      def get_nearest_minute_data_helper(time, source_name, keys, function = "AVG", time_i_key = nil)
        return nil
      end

      def round_to_minute_helper(time)
        return nil
      end

      def kramdown_subordinates(segment_node_id, segment_index)
        return super unless at_destination?
        return kramdown_subordinates_sublist(segment_node_id, segment_index)
      end
    end

  end
end

