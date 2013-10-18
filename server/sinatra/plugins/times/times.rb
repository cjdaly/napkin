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
  class Times < PluginBase
    def init
      times_node_id = init_service_segment
      @times_ce_node_id_cached = Neo.get_sub_id!('ce', times_node_id)
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

    def get_nearest_minute_node_id!(time)
      rounded_time = round_to_minute(time)

      cypher_hash = {
        "query" => CREATE_MINUTE_NODE_CYPHER,
        "params" => {
        "times_ce_node_id" => @times_ce_node_id_cached,
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
    WHERE ((year.`napkin.segment` = {year_segment})
      AND (month.`napkin.segment` = {month_segment})
      AND (day.`napkin.segment` = {day_segment})
      AND (hour.`napkin.segment` = {hour_segment})
      AND (minute.`napkin.segment` = {minute_segment}))
    RETURN ID(minute)
    '

    def get_nearest_minute_node_id(time)
      rounded_time = round_to_minute(time)

      cypher_hash = {
        "query" => GET_MINUTE_NODE_CYPHER,
        "params" => {
        "times_ce_node_id" => @times_ce_node_id_cached,
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
    WHERE ((year.`napkin.segment` = {year_segment})
      AND  (month.`napkin.segment` = {month_segment})
      AND  (day.`napkin.segment` = {day_segment})
      AND  (hour.`napkin.segment` = {hour_segment})
      AND  (minute.`napkin.segment` = {minute_segment})
      AND  (source_ref.`times.source` = {source_name}))
    RETURN_STATEMENT
    ORDER_BY_STATEMENT
    '

    def get_nearest_minute_data(time, source_name, keys, function = "AVG", time_i_key = nil)
      rounded_time = round_to_minute(time)

      return_statement = nil
      keys.each do |key|
        if (return_statement.nil?) then
          return_statement = "RETURN #{function}(sources.`#{key}`)"
        else
          return_statement << ", #{function}(sources.`#{key}`)"
        end
      end
      query_text = GET_MINUTE_DATA_CYPHER.sub(/RETURN_STATEMENT/, return_statement)

      if (time_i_key.nil?) then
        order_by_statement = ""
      else
        order_by_statement = "ORDER BY sources.`#{time_i_key}`"
      end
      query_text.sub!(/ORDER_BY_STATEMENT/, order_by_statement)

      cypher_hash = {
        "query" => query_text,
        "params" => {
        "times_ce_node_id" => @times_ce_node_id_cached,
        "year_segment" => rounded_time.year.to_s,
        "month_segment" => rounded_time.month.to_s,
        "day_segment" => rounded_time.day.to_s,
        "hour_segment" => rounded_time.hour.to_s,
        "minute_segment" => rounded_time.min.to_s,
        "source_name" => source_name
        }
      }

      minute_data = Neo.cypher_query(cypher_hash, false)
      return minute_data
    end

    def round_to_minute(time, interval_minutes = 1)
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