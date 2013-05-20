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
require 'napkin-plugins'
require 'napkin-tasks'
require 'napkin-handlers'
require 'gchart'
require 'haml'

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
      def init
        vitals_node_id = Neo.get_sub_id!('vitals', Neo.pin(:napkin))
        Neo.set_node_property('napkin.handlers.GET.class_name', 'Handler_Vitals_Get', vitals_node_id)

        @task_data['vitals.sup_node_id'] = vitals_node_id
        @task_data['vitals.skip_count'] = 0
        @task_data['vitals.skip_count_max'] = 6
      end

      def todo?
        skip_count = @task_data['vitals.skip_count'] + 1
        if (skip_count > @task_data['vitals.skip_count_max']) then
          @task_data['vitals.skip_count'] = 0
          return true
        else
          @task_data['vitals.skip_count'] = skip_count
          return false
        end
      end

      MEMFREE_CAPTURE = /^MemFree:\s+(\d+)\skB/
      DB_USAGE_CAPTURE = /^(\d+)\s+/

      def doit
        vitals_check_time_i = Time.now.to_i
        vitals_node_id = Neo.next_sub_id!(@task_data['vitals.sup_node_id'])
        Neo.set_node_property('vitals.check_time_i', vitals_check_time_i, vitals_node_id)

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
        loadavg_5_min = parse_float(loadavg_split[1])
        Neo.set_node_property('vitals.loadavg_5_min', loadavg_5_min, vitals_node_id)
        loadavg_15_min = parse_float(loadavg_split[2])
        Neo.set_node_property('vitals.loadavg_15_min', loadavg_15_min, vitals_node_id)

        # database disk usage
        neo4j_db_path = Neo.get_node_property('napkin.config.Neo4J_db_path', Neo.pin(:napkin))
        if (!neo4j_db_path.to_s.empty?) then
          neo4j_db_du = `du -sk #{neo4j_db_path}`
          neo4j_db_du_kb_text = DB_USAGE_CAPTURE.match(neo4j_db_du).captures[0]
          neo4j_db_du_kb = parse_int(neo4j_db_du_kb_text)
          Neo.set_node_property('vitals.neo4j_db_usage_kb', neo4j_db_du_kb, vitals_node_id)
        end
      end
    end
  end

  module Handlers
    class Handler_Vitals_Get < DefaultGetHandler
      def handle
        time_now_i = Time.now.to_i
        start_time_i = time_now_i-600
        end_time_i = time_now_i

        time_interval_seconds = 600
        time_slices = 10

        memfree_avgs = []
        neo4j_db_usage_avgs = []
        time_labels = []

        for i in 1..time_slices
          start_time_i = time_now_i - (time_interval_seconds * i)
          end_time_i = start_time_i + time_interval_seconds
          values = get_averages(start_time_i, end_time_i)
          memfree_avgs.insert(0, (values[1] || 0))
          neo4j_db_usage_avgs.insert(0, (values[2] || 0))
          time_labels.insert(0, Time.at(start_time_i).strftime("%I:%M"))
        end

        start_time_i = time_now_i - (time_interval_seconds * time_slices)
        end_time_i = time_now_i

        minimums = get_minimums(start_time_i, end_time_i)
        maximims = get_maximums(start_time_i, end_time_i)

        memfree_y = [0, maximims[1]]
        memfree_chart = Gchart.line(
        :title => "free memory (kb)",
        :data => memfree_avgs,
        :size => "640x200",
        :axis_with_labels => 'x,y',
        :axis_labels => [time_labels, memfree_y],
        :format => 'image_tag'
        )

        neo4j_db_usage_y = [0, maximims[2]]
        neo4j_db_usage_chart = Gchart.line(
        :title => "Neo4j disk usage (kb)",
        :data => neo4j_db_usage_avgs,
        :size => "640x200",
        :axis_with_labels => 'x,y',
        :axis_labels => [time_labels, neo4j_db_usage_y],
        :format => 'image_tag'
        )

        @response.headers['Content-Type'] = 'text/html'

        haml_text = "%html\n"
        haml_text << "  %body\n"
        haml_text << "    %h1 Napkin vitals\n"
        haml_text << "    %br\n"
        haml_text << "    ! #{memfree_chart}\n"
        haml_text << "    %br\n"
        haml_text << "    ! #{neo4j_db_usage_chart}\n"
        haml_engine = Haml::Engine.new(haml_text)
        return haml_engine.render
      end

      def get_averages(start_time_i, end_time_i)
        cypher_query_returns = "RETURN COUNT(sub)"
        cypher_query_returns << ", avg(sub.`vitals.memfree_kb`?)"
        cypher_query_returns << ", avg(sub.`vitals.neo4j_db_usage_kb`?)"
        return get_interval_data(start_time_i, end_time_i, cypher_query_returns)
      end

      def get_minimums(start_time_i, end_time_i)
        cypher_query_returns = "RETURN COUNT(sub)"
        cypher_query_returns << ", min(sub.`vitals.memfree_kb`?)"
        cypher_query_returns << ", min(sub.`vitals.neo4j_db_usage_kb`?)"
        return get_interval_data(start_time_i, end_time_i, cypher_query_returns)
      end

      def get_maximums(start_time_i, end_time_i)
        cypher_query_returns = "RETURN COUNT(sub)"
        cypher_query_returns << ", max(sub.`vitals.memfree_kb`?)"
        cypher_query_returns << ", max(sub.`vitals.neo4j_db_usage_kb`?)"
        return get_interval_data(start_time_i, end_time_i, cypher_query_returns)
      end

      def get_interval_data(start_time_i, end_time_i, cypher_query_returns)
        cypher_query = "START sup=node({sup_node_id}) "
        cypher_query << "MATCH sup-[:NAPKIN_SUB]->sub "
        cypher_query << "WHERE ( (sub.`vitals.check_time_i` >= {start_time_i}) and (sub.`vitals.check_time_i` < {end_time_i}) ) "
        cypher_query << cypher_query_returns

        cypher_query_hash = {
          "query" => cypher_query,
          "params" => {
          "sup_node_id" => @segment_node_id,
          "start_time_i" => start_time_i,
          "end_time_i" => end_time_i,
          }
        }

        values = Neo.cypher_query(cypher_query_hash)
        return values
      end

    end
  end
end
