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
require 'kramdown-util'
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

        minute_node_id = Napkin::Plugins::Plugin_Times.get_nearest_minute_node_id!(vitals_check_time)
        ref_id = Neo.set_ref!(vitals_node_id, minute_node_id)
        Neo.set_ref_property('times.source', 'napkin.vitals', ref_id)
      end
    end
  end

  module Handlers
    class Handler_Vitals_Get < SubListGetHandler
      PT = Napkin::Plugins::Plugin_Times
      def get_nearest_minute_data_helper(time, source_name, keys, function = "AVG", time_i_key = nil)
        return PT.get_nearest_minute_data(time, source_name, keys, function, time_i_key)
      end

      def round_to_minute_helper(time)
        return PT.round_to_minute(time)
      end

      def kramdown_specials(segment_node_id, segment_index)
        return super unless at_destination?

        kramdown_text = "| *Specials* | *name*\n"
        kramdown_text << "| | [chart1](#{get_path()}/charts?offset=0&samples=120&skip=5&source=napkin.vitals&keys=vitals.memfree_kb,vitals.vmpeak_kb_neo4j,vitals.vmpeak_kb_sinatra)\n"
        return kramdown_text
      end
    end
  end
end
