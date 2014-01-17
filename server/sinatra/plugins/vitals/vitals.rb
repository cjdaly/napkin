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
  class Vitals < PluginBase
    def init
      vitals_node_id = init_service_segment(neo.pin(:napkin))

      # TODO: clean up
      neo.pin!(:vitals, vitals_node_id)

      register_handler('get', Get_Handler)
      attach_handler('get', 'GET', vitals_node_id)

      starts_node_id = neo.pin(:starts)
      register_handler('get_starts', Get_Starts_Handler)
      attach_handler('get_starts', 'GET', starts_node_id)

      register_task('main', Vitals_Task)
    end

    class Get_Starts_Handler < Napkin::Handlers::SubListGetHandler
    end

    class Get_Handler < Napkin::Handlers::SubListGetHandler
      def kramdown_features(node_id)
        return super unless at_destination?

        kramdown_text ="\n###Features\n\n"
        kramdown_text << "| *name*\n"
        kramdown_text << "| chart memory usage "
        kramdown_text << "| [1 min](#{get_memory_chart_url(1)}) "
        kramdown_text << "| [5 min](#{get_memory_chart_url(5)}) "
        kramdown_text << "| [10 min](#{get_memory_chart_url(10)}) "
        kramdown_text << "| [15 min](#{get_memory_chart_url(15)}) "
        kramdown_text << "| [30 min](#{get_memory_chart_url(30)}) "
        kramdown_text << "| [60 min](#{get_memory_chart_url(60)})\n"

        kramdown_text << chart_table_helper("Neo4j DB disk usage", "vitals.neo4j_db_usage_kb")
        kramdown_text << chart_table_helper("load average", "vitals.loadavg_1_min")
        return kramdown_text
      end

      def chart_table_helper(name, data_key)
        kramdown_text = "| chart #{name}"
        kramdown_text << "| [1 min](#{get_single_chart_url(1, data_key)})"
        kramdown_text << "| [5 min](#{get_single_chart_url(5, data_key)})"
        kramdown_text << "| [10 min](#{get_single_chart_url(10, data_key)})"
        kramdown_text << "| [15 min](#{get_single_chart_url(15, data_key)})"
        kramdown_text << "| [30 min](#{get_single_chart_url(30, data_key)})"
        kramdown_text << "| [60 min](#{get_single_chart_url(60, data_key)})"
        kramdown_text << "\n"
      end

      def get_memory_chart_url(skip)
        return "#{get_path}/charts?offset=0&samples=120&skip=#{skip}&source=napkin.vitals&keys=vitals.memfree_kb,vitals.vmpeak_kb_neo4j,vitals.vmpeak_kb_sinatra"
      end

      def get_single_chart_url(skip, key)
        return "#{get_path}/charts?offset=0&samples=120&skip=#{skip}&source=napkin.vitals&data_key=#{key}&time_i_key=vitals.check_time_i"
      end
    end

    class Vitals_Task < Napkin::Tasks::TaskBase
      NEO4J_PID_CAPTURE = /^Neo4j Server is running at pid (\d+)/
      def init
        @sup_node_id = neo.pin(:vitals)
        @skip_count = 0
        @skip_count_max = 6

        @sinatra_pid = Process.pid

        neo4j_status = `neo4j status`
        @neo4j_pid = NEO4J_PID_CAPTURE.match(neo4j_status).captures[0]
      end

      def todo?
        skip_count = @skip_count + 1
        if (skip_count >= @skip_count_max) then
          @skip_count = 0
          return true
        else
          @skip_count = skip_count
          return false
        end
      end

      VMPEAK_CAPTURE = /^VmPeak:\s+(\d+)\skB/
      MEMFREE_CAPTURE = /^MemFree:\s+(\d+)\skB/
      DB_USAGE_CAPTURE = /^(\d+)\s+/

      def doit
        vitals_check_time = Time.now
        vitals_check_time_i = vitals_check_time.to_i
        sub_list = Napkin::Neo4j::SubList.new(@sup_node_id, neo)
        vitals_node_id = sub_list.next_sub_id!
        neo.set_node_property('vitals.check_time_i', vitals_check_time_i, vitals_node_id)

        # VmPeak for Neo4j
        vmpeak_kb_neo4j_raw = `cat /proc/#{@neo4j_pid}/status | grep VmPeak`
        vmpeak_kb_neo4j = VMPEAK_CAPTURE.match(vmpeak_kb_neo4j_raw).captures[0]
        vmpeak_kb_neo4j_i = parse_int(vmpeak_kb_neo4j)
        neo.set_node_property('vitals.vmpeak_kb_neo4j', vmpeak_kb_neo4j_i, vitals_node_id)

        # check limit and restart if exceeded
        neo4j_vmpeak_limit = napkin_driver.system_config['napkin.config.Neo4J_VmPeak_limit_kb']
        if (!neo4j_vmpeak_limit.nil?) then
          if (vmpeak_kb_neo4j_i > neo4j_vmpeak_limit) then
            napkin_driver.restart("Vitals_Task: Neo4j VmPeak usage exceeded: #{vmpeak_kb_neo4j_i} / #{neo4j_vmpeak_limit}")
          end
        end

        # VmPeak for Sinatra
        vmpeak_kb_sinatra_raw = `cat /proc/#{@sinatra_pid}/status | grep VmPeak`
        vmpeak_kb_sinatra = VMPEAK_CAPTURE.match(vmpeak_kb_sinatra_raw).captures[0]
        vmpeak_kb_sinatra_i = parse_int(vmpeak_kb_sinatra)
        neo.set_node_property('vitals.vmpeak_kb_sinatra', vmpeak_kb_sinatra_i, vitals_node_id)

        # free memory
        memfree = `cat /proc/meminfo | grep MemFree`
        memfree_kb = MEMFREE_CAPTURE.match(memfree).captures[0]
        memfree_kb_i = parse_int(memfree_kb)
        neo.set_node_property('vitals.memfree_kb', memfree_kb_i, vitals_node_id)

        # load averages
        loadavg = `cat /proc/loadavg`
        loadavg_split = loadavg.split
        loadavg_1_min = parse_float(loadavg_split[0])
        neo.set_node_property('vitals.loadavg_1_min', loadavg_1_min, vitals_node_id)

        # database disk usage
        neo4j_db_path = neo.get_node_property('napkin.config.Neo4J_db_path', neo.pin(:napkin))
        if (!neo4j_db_path.to_s.empty?) then
          neo4j_db_du = `du -sk #{neo4j_db_path}`
          neo4j_db_du_kb_text = DB_USAGE_CAPTURE.match(neo4j_db_du).captures[0]
          neo4j_db_du_kb = parse_int(neo4j_db_du_kb_text)
          neo.set_node_property('vitals.neo4j_db_usage_kb', neo4j_db_du_kb, vitals_node_id)
        end

        # check memory usage within bounds
        neo4j_process_limit = napkin_driver.system_config['napkin.config.Neo4J_process_limit_kb']

        # connect to time index
        plugin_times = get_plugin('times')
        minute_node_id = plugin_times.get_nearest_minute_node_id!(vitals_check_time)
        ref_id = neo.set_ref!(vitals_node_id, minute_node_id)
        neo.set_ref_property('times.source', 'napkin.vitals', ref_id)
      end
    end

  end
end
