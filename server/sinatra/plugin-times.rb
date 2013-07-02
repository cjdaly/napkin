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
    class Plugin_Times < PluginBase
      def get_segment
        return 'times'
      end

      def get_task_class_name
        return 'Task_Times'
      end

      CREATE_MINUTE_NODE_CYPHER ='
      START times_ce=node({times_ce_node_id})
      CREATE UNIQUE times_ce-[:NAPKIN_SUB]->
        (year {`napkin.segment` : {year_segment}})-[:NAPKIN_SUB]->
        (month {`napkin.segment` : {month_segment}})-[:NAPKIN_SUB]->
        (day {`napkin.segment` : {day_segment}})-[:NAPKIN_SUB]->
        (hour {`napkin.segment` : {hour_segment}})-[:NAPKIN_SUB]->
        (minute {`napkin.segment` : {minute_segment}})
      RETURN ID(minute)
      '

      def Plugin_Times.get_nearest_minute_node_id!(time)
        rounded_time = Plugin_Times.round_to_minute(time)

        cypher_hash = {
          "query" => CREATE_MINUTE_NODE_CYPHER,
          "params" => {
          "times_ce_node_id" => Neo.pin(:times_ce),
          "year_segment" => rounded_time.year.to_s,
          "month_segment" => rounded_time.month.to_s,
          "day_segment" => rounded_time.day.to_s,
          "hour_segment" => rounded_time.hour.to_s,
          "minute_segment" => rounded_time.min.to_s
          }
        }

        minute_node_id = Neo.cypher_query(cypher_hash, true)
        return minute_node_id
      end

      GET_MINUTE_NODE_CYPHER ='
      START times_ce=node({times_ce_node_id})
      MATCH times_ce-[:NAPKIN_SUB]->
        (year)-[:NAPKIN_SUB]->
        (month)-[:NAPKIN_SUB]->
        (day)-[:NAPKIN_SUB]->
        (hour)-[:NAPKIN_SUB]->
        (minute)
      WHERE ((year.`napkin.segment`! = {year_segment})
        AND (month.`napkin.segment`! = {month_segment})
        AND (day.`napkin.segment`! = {day_segment})
        AND (hour.`napkin.segment`! = {hour_segment})
        AND (minute.`napkin.segment`! = {minute_segment}))
      RETURN ID(minute)
      '

      def Plugin_Times.get_nearest_minute_node_id(time)
        rounded_time = Plugin_Times.round_to_minute(time)

        cypher_hash = {
          "query" => GET_MINUTE_NODE_CYPHER,
          "params" => {
          "times_ce_node_id" => Neo.pin(:times_ce),
          "year_segment" => rounded_time.year.to_s,
          "month_segment" => rounded_time.month.to_s,
          "day_segment" => rounded_time.day.to_s,
          "hour_segment" => rounded_time.hour.to_s,
          "minute_segment" => rounded_time.min.to_s
          }
        }

        minute_node_id = Neo.cypher_query(cypher_hash, true)
        return minute_node_id
      end

      GET_MINUTE_DATA_CYPHER ='
      START times_ce=node({times_ce_node_id})
      MATCH times_ce-[:NAPKIN_SUB]->
        (year)-[:NAPKIN_SUB]->
        (month)-[:NAPKIN_SUB]->
        (day)-[:NAPKIN_SUB]->
        (hour)-[:NAPKIN_SUB]->
        (minute)<-[source_ref:NAPKIN_REF]-(sources)
      WHERE ((year.`napkin.segment`! = {year_segment})
        AND  (month.`napkin.segment`! = {month_segment})
        AND  (day.`napkin.segment`! = {day_segment})
        AND  (hour.`napkin.segment`! = {hour_segment})
        AND  (minute.`napkin.segment`! = {minute_segment})
        AND  (source_ref.`times.source`! = {source_name}))
      RETURN_STATEMENT
      ORDER_BY_STATEMENT
      '

      def Plugin_Times.get_nearest_minute_data(time, source_name, keys, function = "AVG", time_i_key = nil)
        rounded_time = Plugin_Times.round_to_minute(time)

        return_statement = nil
        keys.each do |key|
          if (return_statement.nil?) then
            return_statement = "RETURN #{function}(sources.`#{key}`?)"
          else
            return_statement << ", #{function}(sources.`#{key}`?)"
          end
        end

        query_text = GET_MINUTE_DATA_CYPHER.sub(/RETURN_STATEMENT/, return_statement)
        cypher_hash = {
          "query" => query_text,
          "params" => {
          "times_ce_node_id" => Neo.pin(:times_ce),
          "year_segment" => rounded_time.year.to_s,
          "month_segment" => rounded_time.month.to_s,
          "day_segment" => rounded_time.day.to_s,
          "hour_segment" => rounded_time.hour.to_s,
          "minute_segment" => rounded_time.min.to_s,
          "source_name" => source_name
          }
        }

        if (time_i_key.nil?) then
          order_by_statement = ""
        else
          order_by_statement = "ORDER BY sources.`#{time_i_key}`?"
        end
        query_text.sub!(/ORDER_BY_STATEMENT/, order_by_statement)

        minute_data = Neo.cypher_query(cypher_hash, false)
        return minute_data
      end

      def Plugin_Times.round_to_minute(time, interval_minutes = 1)
        time_i = time.to_i
        interval_seconds = 60 * interval_minutes

        time_mod = time_i % interval_seconds
        if (time_mod < (interval_seconds / 2)) then
          rounded_time_i = time_i - time_mod
        else
          rounded_time_i = (time_i - time_mod) + interval_seconds
        end

        rounded_time = Time.at(rounded_time_i)
        return rounded_time
      end
    end
  end

  module Tasks
    class Task_Times < TaskBase
      def init
        root_node_id = Neo.pin(:root)
        times_node_id = Neo.get_sub_id!('times', root_node_id)
        times_ce_node_id = Neo.get_sub_id!('ce', times_node_id)
        # TODO: is there a better caching mechanism than 'pin'?
        Neo.pin!(:times_ce, times_ce_node_id)

        times_now_node_id = Neo.get_sub_id!('now', times_node_id)
        Neo.set_node_property('napkin.handlers.GET.class_name', 'Handler_Times_Now_Get', times_now_node_id)
      end

      def todo?
        return false
      end

      def doit
      end
    end
  end

  module Handlers
    class Handler_Times_Now_Get < DefaultGetHandler
      PT = Napkin::Plugins::Plugin_Times
      #
      def handle
        if (get_param('data_key').nil?) then
          handle_orig
        else
          handle_new
        end
      end

      def handle_new
        handle_time = Time.now
        minute_time = PT.round_to_minute(handle_time)
        minute_time_i = minute_time.to_i
        total_minutes = 15

        param_source = get_param('source')
        param_time_i_key = get_param('time_i_key')
        param_data_key = get_param('data_key')

        if (param_source.nil? || param_time_i_key.nil?) then
          param_source = 'napkin.vitals'
          keys = ['vitals.check_time_i', 'vitals.memfree_kb']
        else
          keys = [param_time_i_key, param_data_key]
        end

        minute_time_i = minute_time_i - (60 * total_minutes)
        time_series = []
        for i in 1..total_minutes
          minute_time_i += 60
          minute_time = Time.at(minute_time_i)

          data = PT.get_nearest_minute_data(minute_time, param_source, keys, function="")
          data.each do |time_value|
            time_i = time_value[0]
            time = Time.at(time_i)
            time_javascript = "new Date(#{time.year},#{time.month-1},#{time.day},#{time.hour},#{time.min},#{time.sec})"

            value = time_value[1]

            time_series << [time_javascript, value]
          end
        end

        @response.headers['Content-Type'] = 'text/html'
        value_labels = keys
        haml_out = Haml.render_line_chart(param_data_key, value_labels, time_series)
        return haml_out
      end

      def handle_orig
        handle_time = Time.now
        minute_time = PT.round_to_minute(handle_time)
        minute_time_i = minute_time.to_i
        total_minutes = 15

        param_source = get_param('source')
        param_keys = get_param('keys', false)

        if (param_source.nil? || param_keys.nil?) then
          param_source = 'napkin.vitals'
          keys = ['vitals.memfree_kb']
        else
          keys = []
          param_keys.split(',').each do |key|
            if (Neo.valid_segment?(key)) then
              keys << key
            end
          end
        end

        minute_time_i = minute_time_i - (60 * total_minutes)
        time_series = []
        for i in 1..total_minutes
          minute_time_i += 60
          minute_time = Time.at(minute_time_i)
          row = ["new Date(#{minute_time.year},#{minute_time.month-1},#{minute_time.day},#{minute_time.hour},#{minute_time.min})"]

          data = PT.get_nearest_minute_data(minute_time, param_source, keys)
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
        haml_out = Haml.render_line_chart('Napkin data now!', value_labels, time_series)
        return haml_out
      end
    end
  end
end
