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
require 'yaml'
require 'rss/2.0'
require 'cgi'

#
require 'rubygems'
require 'neo4j'

#
require 'napkin-config'
require 'napkin-node-util'
require 'napkin-handlers'
require 'napkin-extensions'

module Napkin
  module Handlers
    class SketchupModelsPostHandler < HttpMethodHandler
      def handle
        return "" unless at_destination?
        post_time = Time.now

        @request.body.rewind
        body_text = @request.body.read
        body_hash = Napkin::Extensions::Tasks::SketchupTask::SKETCHUP_MODELS_GROUP.yaml_to_hash(body_text, filter=false)

        puts "Sketchup Model post from #{@user}:\n#{body_text}"

        id = body_hash[NAPKIN_ID]
        return "SketchupModelsPostHandler: missing id!" if id.nil?

        nn = @nn.dup
        nn.go_sub!(id)

        nn[NAPKIN_HTTP_POST] = "SketchupModelsPostHandler"
        nn[NAPKIN_HTTP_GET] = "SketchupModelsGetHandler"

        nn.set_key_prefix('sketchup.models', '~')
        Napkin::Extensions::Tasks::SketchupTask::SKETCHUP_MODELS_GROUP.hash_to_node(nn.node, body_hash)

        return "OK"
      end
    end

    class SketchupModelsGetHandler < HttpMethodHandler
      def handle
        if (at_destination?) then
          return super
        end

        result = ""

        if (!next_stop_destination?) then
          return result
        end

        curr_segment = get_segment
        next_segment = get_next_segment

        nn = @nn.dup
        nn.set_key_prefix('sketchup.models', '~')
        title = nn['title']
        kind = nn['kind']

        info = SketchupInfo.new(@request.query_string)

        if (next_segment == "rss.xml") then
          result << "<?xml version=\"1.0\"?>\n"
          result << "<rss version=\"2.0\">\n"
          result << "  <channel>\n"
          result << "    <title>#{title}</title>\n"
          result << "    <link>#{curr_segment}</link>\n"
          result << "    <description>Feed description</description>\n"
          #
          # preamble
          result << "    <item>\n"
          result << "      <title>preamble</title>\n"
          result << "      <category>ruby</category>\n"
          result << "      <link>preamble.rb</link>\n"
          result << "    </item>\n"
          #
          # node-defined model sub elements
          nn.node.outgoing(NAPKIN_SUB).each do |sub|
            sub_id = sub[NAPKIN_ID]
            result << "    <item>\n"
            result << "      <title>#{sub_id}</title>\n"
            result << "      <category>rss</category>\n"
            result << "      <link>#{sub_id}</link>\n"
            result << "    </item>\n"
          end
          #
          # virtual sub elements
          case kind
          when "top"
            result << handle_top_virtual_subs(info)
          when "timeline"
            result << handle_timeline_virtual_subs(info)
          when "dataline"
            result << handle_dataline_virtual_subs(info)
          end
          #
          # postamble
          result << "    <item>\n"
          result << "      <title>postamble</title>\n"
          result << "      <category>ruby</category>\n"
          result << "      <link>postamble.rb</link>\n"
          result << "    </item>\n"
          result << "  </channel>\n"
          result << "</rss>\n"
        elsif (next_segment == "preamble.rb") then
          case kind
          when "top"
            result << handle_top_preamble(info)
          when "timeline"
            result << handle_timeline_preamble(info)
          when "dataline"
            result << handle_dataline_preamble(info)
          end
        elsif (next_segment == "vsub.rb") then
          case kind
          when "top"
            result << handle_top_virtual_sub(info)
          when "timeline"
            result << handle_timeline_virtual_sub(info)
          when "dataline"
            result << handle_dataline_virtual_sub(info)
          end
        elsif (next_segment == "postamble.rb") then
          case kind
          when "top"
            result << handle_top_postamble(info)
          when "timeline"
            result << handle_timeline_postamble(info)
          when "dataline"
            result << handle_dataline_postamble(info)
          end
        end

        return result
      end

      # top-level model node
      #
      def handle_top_preamble(info, result="")
        result << "set_data('top_group', Sketchup.active_model.entities.add_group)\n"
        return result
      end

      def handle_top_virtual_subs(info, result="")
        result << "puts 'in handle_top_virtual_subs'\n"
        return result
      end

      def handle_top_virtual_sub(info, result="")
        result << "puts 'in handle_top_virtual_sub'\n"
        return result
      end

      def handle_top_postamble(info, result="")
        result << "g = get_data('top_group')\n"
        result << "g.entities.transform_entities [0,100,0], g\n"
        return result
      end

      # timeline
      #
      def handle_timeline_preamble(info, result="")
        result << "g = get_data('top_group')\n"
        result << "set_data('timeline_group', g.entities.add_group)\n"
        return result
      end

      def handle_timeline_virtual_subs(info, result="")
        (info.param_start_time_i..info.param_end_time_i).step(info.get_unit) do |loop_time_i|
          result << "    <item>\n"
          result << "      <title>vsub</title>\n"
          result << "      <category>ruby</category>\n"
          result << "      <link>vsub.rb?ref_time_i=#{info.param_ref_time_i}&start_time_i=#{loop_time_i}&end_time_i=#{loop_time_i+info.get_unit-1}&x_per_hour=#{info.param_x}&y_display_area=#{info.param_y}&z_base_level=#{info.param_z}</link>\n"
          result << "    </item>\n"
        end
        return result
      end

      def handle_timeline_virtual_sub(info, result="")
        result << "g = get_data('timeline_group')\n"
        result << "face_group = g.entities.add_group\n"
        result << "x1 = #{info.get_x(info.param_start_time_i)}\n"
        result << "x2 = x1 + #{info.param_x} - 1\n"
        result << "y1 = 0\n"
        result << "y2 = y1 + #{info.param_y}\n"
        result << "z = #{info.param_z}\n"
        result << "face_bounds = [[x1,y1,z],[x2,y1,z],[x2,y2,z],[x1,y2,z]]\n"
        result << "face = face_group.entities.add_face face_bounds\n"
        result << "face_group.material = 'Green'\n"
        result << "time=Time.at(#{info.param_start_time_i})\n"
        result << "time_text=time.strftime('%H:%M')\n"
        result << "text_group = g.entities.add_group\n"
        result << "text_group.entities.add_3d_text time_text, TextAlignLeft, 'Courier New', true, false, 12, 1, 0, true, 0\n"
        result << "text_group.entities.transform_entities [x1+10,y1+40,1], text_group\n"
        return result
      end

      def handle_timeline_postamble(info, result="")
        result << "puts 'in handle_timeline_postamble'\n"
        return result
      end

      # dataline
      #
      def handle_dataline_preamble(info, result="")
        result << "g = get_data('top_group')\n"
        result << "set_data('dataline_group', g.entities.add_group)\n"
        return result
      end

      def handle_dataline_virtual_subs(info, result="")
        (info.param_start_time_i..info.param_end_time_i).step(info.get_unit) do |loop_time_i|
          result << "    <item>\n"
          result << "      <title>vsub</title>\n"
          result << "      <category>ruby</category>\n"
          result << "      <link>vsub.rb?ref_time_i=#{info.param_ref_time_i}&start_time_i=#{loop_time_i}&end_time_i=#{loop_time_i+info.get_unit-1}&x_per_hour=#{info.param_x}&y_display_area=#{info.param_y}&z_base_level=#{info.param_z}</link>\n"
          result << "    </item>\n"
        end
        return result
      end

      def handle_dataline_virtual_sub(info, result="")
        result << "g = get_data('dataline_group')\n"
        result << "face_groups = g.entities.add_group\n"
        result << handle_datapoints(info)
        return result
      end

      def handle_datapoints(info, result="")
        nn = Napkin::NodeUtil::NodeNav.new
        nn.go_sub_path!("chatter/cerbee1")

        nn.node.outgoing(NAPKIN_SUB).each do |sub|
          post_time_i = sub['chatter.post~time_i']
          if (!post_time_i.nil?) then
            if ((post_time_i >= info.param_start_time_i) && (post_time_i < info.param_end_time_i)) then
              light_text = sub['chatter.device.sensor.light_sensor_percentage~average']
              light_f = convert_to_f(light_text)
              if (!light_f.nil?) then
                result << "face_group = face_groups.entities.add_group\n"
                result << "x1 = #{info.get_x(post_time_i).to_s}\n"
                result << "x2 = x1 + 4\n"
                result << "y1 = 80\n"
                result << "y2 = y1 + 4\n"
                result << "z = #{info.param_z}\n"
                result << "face_bounds = [[x1,y1,z],[x2,y1,z],[x2,y2,z],[x1,y2,z]]\n"
                result << "face = face_group.entities.add_face face_bounds\n"
                result << "face.reverse!\n"
                result << "face.pushpull #{light_f}\n"
                result << "face_group.material = 'Gray'\n"
              end

              temp_text = sub['chatter.device.sensor.temperature~average']
              temp_f = convert_to_f(temp_text)
              if (!temp_f.nil?) then
                result << "face_group = face_groups.entities.add_group\n"
                result << "x1 = #{info.get_x(post_time_i).to_s}\n"
                result << "x2 = x1 + 4\n"
                result << "y1 = 90\n"
                result << "y2 = y1 + 4\n"
                result << "z = #{info.param_z}\n"
                result << "face_bounds = [[x1,y1,z],[x2,y1,z],[x2,y2,z],[x1,y2,z]]\n"
                result << "face = face_group.entities.add_face face_bounds\n"
                result << "face.reverse!\n"
                result << "face.pushpull #{temp_f}\n"
                result << "face_group.material = 'Blue'\n"
              end

              humidity_text = sub['chatter.device.sensor.humidity~average']
              humidity_f = convert_to_f(humidity_text)
              if (!humidity_f.nil?) then
                result << "face_group = face_groups.entities.add_group\n"
                result << "x1 = #{info.get_x(post_time_i).to_s}\n"
                result << "x2 = x1 + 4\n"
                result << "y1 = 100\n"
                result << "y2 = y1 + 4\n"
                result << "z = #{info.param_z}\n"
                result << "face_bounds = [[x1,y1,z],[x2,y1,z],[x2,y2,z],[x1,y2,z]]\n"
                result << "face = face_group.entities.add_face face_bounds\n"
                result << "face.reverse!\n"
                result << "face.pushpull #{humidity_f}\n"
                result << "face_group.material = 'Orange'\n"
              end

            end
          end
        end

        return result
      end

      def convert_to_f(text)
        f = nil
        if (text.is_a? String) then
          begin
            f = Float(text)
          rescue ArgumentError => err
          end
        end
        return f
      end

      def handle_dataline_postamble(info, result="")
        result << "puts 'in handle_dataline_postamble'\n"
        return result
      end

    end

    class SketchupInfo

      MIN = 60
      HR = MIN * 60
      DAY = HR * 24

      UNIT = HR
      def get_unit
        return UNIT
      end

      attr_reader :param_ref_time_i, :param_start_time_i, :param_end_time_i
      attr_reader :param_x, :param_y, :param_z

      #
      def initialize(query_string)
        @query_string = query_string
        @query_hash = CGI.parse(query_string)
        @time_now = Time.now

        @param_ref_time_i = get_int_param('ref_time_i', @time_now.to_i - DAY, @query_hash)
        @param_start_time_i = get_int_param('start_time_i', @time_now.to_i - (DAY * 5), @query_hash)
        @param_end_time_i = get_int_param('end_time_i', @time_now.to_i, @query_hash)

        @param_x = get_int_param('x_per_hour', 100, @query_hash)
        @param_y = get_int_param('y_display_area', 150, @query_hash)
        @param_z = get_int_param('z_base_level', 0, @query_hash)
      end

      def get_x(time_i)
        return ((time_i - @param_ref_time_i) * @param_x) / UNIT
      end

      def get_duration_time_i
        return @param_end_time_i - @param_start_time_i
      end

      def get_param(name, default, query_hash)
        param = query_hash[name].first
        if (param.nil? || param=="") then
          param = default
        end
        return param
      end

      def get_int_param(name, default, query_hash)
        param = get_param(name, default, query_hash)
        if (param.is_a? String) then
          begin
            param = Integer(param)
          rescue ArgumentError => err
            param = default
          end
        end
        return param
      end
    end
  end

  module Extensions
    module Tasks
      class SketchupTask < Task
        def init
          super
          puts "!!! SketchupTask.init called !!!"
          init_nodes
        end

        def init_nodes
          nn = Napkin::NodeUtil::NodeNav.new
          nn.go_sub_path!('sketchup/models')
          nn[NAPKIN_HTTP_POST] = "SketchupModelsPostHandler"
        end

        def cycle
          super
          puts "!!! SketchupTask.cycle called !!!"
          # refresh_feeds
        end

        SKETCHUP_MODELS_GROUP = Napkin::NodeUtil::PropertyGroup.new('sketchup.models', "~").
        add_property('title').group.
        add_property('kind').group
      end
    end
  end
end