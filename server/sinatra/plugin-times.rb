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
        (minute)<-[producer_ref:NAPKIN_REF]-(producer)
      WHERE ((year.`napkin.segment`! = {year_segment})
        AND  (month.`napkin.segment`! = {month_segment})
        AND  (day.`napkin.segment`! = {day_segment})
        AND  (hour.`napkin.segment`! = {hour_segment})
        AND  (minute.`napkin.segment`! = {minute_segment})
        AND  (producer_ref.`times.producer`! = {producer_name}))
      RETURN_STATEMENT
      '

      def Plugin_Times.get_nearest_minute_data(time, producer_name, keys)
        rounded_time = Plugin_Times.round_to_minute(time)

        return_statement = nil
        keys.each do |key|
          if (return_statement.nil?) then
            return_statement = "RETURN AVG(producer.`#{key}`)"
          else
            return_statement << ", AVG(producer.`#{key}`)"
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
          "producer_name" => producer_name
          }
        }

        minute_data = Neo.cypher_query(cypher_hash, false)
        return minute_data
      end

      def Plugin_Times.round_to_minute(time, message = nil)
        time_i = time.to_i

        if (time.sec < 30) then
          rounded_time_i = time_i - time.sec
        else
          rounded_time_i = time_i + (60 - time.sec)
        end

        rounded_time = Time.at(rounded_time_i)

        if (!message.nil?) then
          rt = rounded_time
          puts "#{message}: #{rt.year}/#{rt.month}/#{rt.day}/#{rt.hour}/#{rt.min}/(#{rt.sec})"
        end

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

      GET_REFS_CYPHER = '
      START minute=node({minute_node_id})
      MATCH refs-[:NAPKIN_REF]->minute
      RETURN ID(refs)
      '
      def handle
        handle_time = Time.now
        minute_time = PT.round_to_minute(handle_time)
        minute_time_i = minute_time.to_i
        total_minutes = 15

        param_producer = get_param('producer')
        param_key = get_param('key')

        if param_producer.nil? then
          param_producer = 'napkin.vitals'
          param_key = 'vitals.memfree_kb'
        end

        minute_time_i = minute_time_i - (60 * total_minutes)
        time_series = []
        for i in 1..total_minutes
          minute_time_i += 60
          minute_time = Time.at(minute_time_i)
          minute_time_label = minute_time.strftime("%I:%M%P")
          data = PT.get_nearest_minute_data(minute_time, param_producer,[param_key])

          row = [minute_time_label]
          bogus = false
          data[0].each do |val|
            if val.nil? then
              bogus = true if (i == total_minutes)
              val = 0
            end
            row << val
          end

          time_series << row unless bogus
        end

        @response.headers['Content-Type'] = 'text/html'
        value_labels = [param_key]
        haml_out = Haml.render_line_chart('Napkin data now!', value_labels, time_series)
        return haml_out
      end
    end
  end
end
