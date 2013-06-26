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
require 'plugin-times'

module Napkin
  module Plugins
    class Plugin_Vitals < PluginBase
      def get_segment
        return 'vitals'
      end

      def get_task_class_name
        return 'Task_Vitals'
      end
    end
  end

  module Tasks
    class Task_Vitals < TaskBase
      NEO4J_PID_CAPTURE = /^Neo4j Server is running at pid (\d+)/
      def init
        vitals_node_id = Neo.get_sub_id!('vitals', Neo.pin(:napkin))
        Neo.set_node_property('napkin.handlers.GET.class_name', 'Handler_Vitals_Get', vitals_node_id)

        @task_data['vitals.sup_node_id'] = vitals_node_id
        @task_data['vitals.skip_count'] = 0
        @task_data['vitals.skip_count_max'] = 6

        @task_data['vitals.sinatra_pid'] = Process.pid

        neo4j_status = `neo4j status`
        @task_data['vitals.neo4j_pid'] = NEO4J_PID_CAPTURE.match(neo4j_status).captures[0]
      end

      def todo?
        skip_count = @task_data['vitals.skip_count'] + 1
        if (skip_count >= @task_data['vitals.skip_count_max']) then
          @task_data['vitals.skip_count'] = 0
          return true
        else
          @task_data['vitals.skip_count'] = skip_count
          return false
        end
      end

      VMPEAK_CAPTURE = /^VmPeak:\s+(\d+)\skB/
      MEMFREE_CAPTURE = /^MemFree:\s+(\d+)\skB/
      DB_USAGE_CAPTURE = /^(\d+)\s+/

      def doit
        vitals_check_time = Time.now
        vitals_check_time_i = vitals_check_time.to_i
        sub_list = Neo::SubList.new(@task_data['vitals.sup_node_id'])
        vitals_node_id = sub_list.next_sub_id!
        Neo.set_node_property('vitals.check_time_i', vitals_check_time_i, vitals_node_id)

        # VmPeak for Neo4j
        vmpeak_kb_neo4j_raw = `cat /proc/#{@task_data['vitals.neo4j_pid']}/status | grep VmPeak`
        vmpeak_kb_neo4j = VMPEAK_CAPTURE.match(vmpeak_kb_neo4j_raw).captures[0]
        vmpeak_kb_neo4j_i = parse_int(vmpeak_kb_neo4j)
        Neo.set_node_property('vitals.vmpeak_kb_neo4j', vmpeak_kb_neo4j_i, vitals_node_id)

        # VmPeak for Sinatra
        vmpeak_kb_sinatra_raw = `cat /proc/#{@task_data['vitals.sinatra_pid']}/status | grep VmPeak`
        vmpeak_kb_sinatra = VMPEAK_CAPTURE.match(vmpeak_kb_sinatra_raw).captures[0]
        vmpeak_kb_sinatra_i = parse_int(vmpeak_kb_sinatra)
        Neo.set_node_property('vitals.vmpeak_kb_sinatra', vmpeak_kb_sinatra_i, vitals_node_id)

        # free memory
        memfree = `cat /proc/meminfo | grep MemFree`
        memfree_kb = MEMFREE_CAPTURE.match(memfree).captures[0]
        memfree_kb_i = parse_int(memfree_kb)
        Neo.set_node_property('vitals.memfree_kb', memfree_kb_i, vitals_node_id)

        # load averages
        loadavg = `cat /proc/loadavg`
        loadavg_split = loadavg.split
        loadavg_1_min = parse_float(loadavg_split[0])
        Neo.set_node_property('vitals.loadavg_1_min', loadavg_1_min, vitals_node_id)
        # loadavg_5_min = parse_float(loadavg_split[1])
        # Neo.set_node_property('vitals.loadavg_5_min', loadavg_5_min, vitals_node_id)
        # loadavg_15_min = parse_float(loadavg_split[2])
        # Neo.set_node_property('vitals.loadavg_15_min', loadavg_15_min, vitals_node_id)

        # database disk usage
        neo4j_db_path = Neo.get_node_property('napkin.config.Neo4J_db_path', Neo.pin(:napkin))
        if (!neo4j_db_path.to_s.empty?) then
          neo4j_db_du = `du -sk #{neo4j_db_path}`
          neo4j_db_du_kb_text = DB_USAGE_CAPTURE.match(neo4j_db_du).captures[0]
          neo4j_db_du_kb = parse_int(neo4j_db_du_kb_text)
          Neo.set_node_property('vitals.neo4j_db_usage_kb', neo4j_db_du_kb, vitals_node_id)
        end

        Napkin::Plugins::Plugin_Times.round_to_minute(vitals_check_time, "VITALS")
        minute_node_id = Napkin::Plugins::Plugin_Times.get_nearest_minute_node_id!(vitals_check_time)
        ref_id = Neo.set_ref!(vitals_node_id, minute_node_id)
        Neo.set_ref_property('times.producer', 'napkin.vitals', ref_id)
      end
    end
  end

  module Handlers
    class Handler_Vitals_Get < DefaultGetHandler
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

        memfree_time_series = Neo.get_time_series(
        @segment_node_id, 'vitals.memfree_kb',
        'vitals.check_time_i', time_now_i,
        10, 600
        )

        neo4j_db_usage_time_series = Neo.get_time_series(
        @segment_node_id, 'vitals.neo4j_db_usage_kb',
        'vitals.check_time_i', time_now_i,
        10, 600
        )

        time_series = neo4j_db_usage_time_series
        time_series.each_with_index do |row, index|
          row << memfree_time_series[index][1]
        end

        @response.headers['Content-Type'] = 'text/html'
        value_labels = ["Neo4j DB usage (kb)", "free memory (kb)"]
        haml_out = Haml.render_line_chart('Napkin vitals', value_labels, time_series)
        return haml_out
      end

    end
  end
end
