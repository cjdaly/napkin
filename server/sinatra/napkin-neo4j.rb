####
# Copyright (c) 2014 Chris J Daly (github user cjdaly)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   cjdaly - initial API and implementation
####

require 'rest_client'
require 'json'
require 'napkin-util'

module Napkin
  module Neo4j
    class Connector
      #
      NAPKIN_VERSION = "0.4.1" # 0.4.x for adopting Neo4j 2.0
      #
      def initialize(napkin_driver)
        @napkin_driver = napkin_driver
        @neo = nil
        @neo4j_connection = false
      end

      def ok?
        return @neo4j_connection
      end

      def neo
        return @neo
      end

      def neo4j_get(url)
        raise "Neo4j connection not available!" unless ok?
        response = RestClient.get(url, :accept=>:json)
        response_json_object = JSON.parse(response.to_s)
        return response_json_object
      end

      def neo4j_post(url, json_object)
        raise "Neo4j connection not available!" unless ok?
        json = json_object.to_json
        response = RestClient.post(url, json, :content_type=>:json, :accept=>:json)
        response_json_object = JSON.parse(response.to_s)
        return response_json_object
      end

      NEO4J_RUNNING_CAPTURE = /^Neo4j Server is( not)? running/

      def neo4j_running?
        neo4j_status = `neo4j status`
        neo4j_running = NEO4J_RUNNING_CAPTURE.match(neo4j_status).captures[0]
        return neo4j_running.to_s.empty?
      end

      def disconnect!
        @neo4j_connection = false
        if (neo4j_running?) then
          puts "Neo4jConnector - stopping Neo4j (this may take a while)..."
          neo4j_stop_text = `neo4j stop`
          puts "#{neo4j_stop_text}"
          raise "Neo4j did not stop!" unless !neo4j_running?
        else
          puts "Neo4jConnector - stopping Neo4j ... already stopped"
        end
      end

      def init_neo()
        if (neo4j_running?) then
          puts "Neo4jConnector - discovered Neo4j already running"
        else
          puts "Neo4jConnector - starting Neo4j (this may take a while)..."
          neo4j_start_text = `neo4j start`
          puts "#{neo4j_start_text}"
          raise "Neo4j did not start!" unless neo4j_running?
        end

        @neo = Neo.new(self)
        @neo4j_connection = true

        start_time = Time.now

        #
        neo.check_cypher_service()
        neo.create_napkin_index()
        neo.create_napkin_root_constraint()

        # create top-level nodes
        neo.pin!(:root, neo.get_root_node_id())
        neo.pin!(:napkin, neo.get_sub_id!('napkin', neo.pin(:root)))

        # Napkin version
        version = neo.get_node_property('napkin.VERSION', neo.pin(:napkin))
        if (version.to_s == "") then
          neo.set_node_property('napkin.VERSION', NAPKIN_VERSION, neo.pin(:napkin))
        elsif (version != NAPKIN_VERSION)
          raise "Neo4jConnector - database/runtime version mismatch! (#{version}/#{NAPKIN_VERSION})"
        end
        puts "Napkin version: #{NAPKIN_VERSION}"

        # system name
        system_name = @napkin_driver.system_config['napkin.config.system_name']
        neo.set_node_property('napkin.config.system_name', system_name, neo.pin(:napkin))

        # Neo4j database path
        neo4j_db_path = @napkin_driver.system_config['napkin.config.Neo4J_db_path']
        neo.set_node_property('napkin.config.Neo4J_db_path', neo4j_db_path, neo.pin(:napkin))

        # starts
        neo.pin!(:starts, neo.get_sub_id!('starts', neo.pin(:napkin)))
        starts_sub_list = SubList.new(neo.pin(:starts), neo)
        neo.pin!(:start, starts_sub_list.next_sub_id!)

        neo.set_node_property('napkin.starts.start_time', "#{start_time}", neo.pin(:start))
        neo.set_node_property('napkin.starts.start_time_i', start_time.to_i, neo.pin(:start))

        start_count = neo.get_node_property('napkin.sublist_count', neo.pin(:starts))
        puts "Napkin system starts: #{start_count}"
      end
    end

    class Neo
      def initialize(connector)
        @connector = connector
        @pinned = {}
      end

      def pin!(node_key, node_id)
        @pinned[node_key] = node_id
      end

      def pin(node_key)
        return @pinned[node_key]
      end

      #
      SR = "http://localhost:7474/db/data"
      SRN = SR + "/node"
      SRB = SR + "/batch"
      SRC = SR + "/cypher"

      #
      def node_url(node_id)
        return "#{SRN}/#{node_id}"
      end

      def get(url)
        return @connector.neo4j_get(url)
      end

      def post(url, json_object)
        return @connector.neo4j_post(url, json_object)
      end

      #
      # TODO: organize/modularize these in some better way
      #

      def cypher_query(cypher_hash, extract_single_result = false)
        raw = post(SRC, cypher_hash)
        raw_data = raw['data']

        if (extract_single_result) then
          return nil if (raw_data.length == 0)
          return nil if (raw_data[0].length == 0)
          return raw_data[0][0]
        else
          return raw_data
        end
      end

      #
      #

      SEGMENT_MATCH = /^[-_.a-zA-Z0-9~]+$/

      def valid_segment?(node_segment)
        return false if node_segment.nil?
        return false unless node_segment.is_a? String
        match = SEGMENT_MATCH.match(node_segment)
        return !match.nil?
      end

      #
      # node property stuff
      #

      def get_node_properties(node_id)
        return get("#{SRN}/#{node_id}/properties")
      end

      def get_node_property(key, node_id)
        return nil unless valid_segment?(key)

        cypher_get_node_property = {
          "query" => "START n=node({node_id}) RETURN n.`#{key}`",
          "params" => {
          "node_id" => node_id,
          }
        }
        value = cypher_query(cypher_get_node_property, true)
        return value
      end

      def set_node_property(key, value, node_id)
        return nil unless valid_segment?(key)

        cypher_set_node_property = {
          "query" => "START n=node({node_id}) SET n.`#{key}`={value} RETURN null",
          "params" => {
          "node_id" => node_id,
          "value" => value,
          }
        }
        raw = post(SRC, cypher_set_node_property)
        return nil
      end

      def increment_counter(key, node_id)
        return nil unless valid_segment?(key)

        cypher_increment_counter = {
          "query" => "START n=node({node_id}) SET n.`#{key}` = COALESCE(n.`#{key}`, 0) + 1 RETURN n.`#{key}`",
          "params" => {
          "node_id" => node_id,
          }
        }
        value = cypher_query(cypher_increment_counter, true)
        return value
      end

      #
      # subordinate stuff
      #

      def next_sub_id!(sup_node_id)
        sub_count = increment_counter('napkin.sub_count', sup_node_id)
        return nil if sub_count.nil?
        sub_node_id =  get_sub_id!(sub_count.to_s, sup_node_id)
        return sub_node_id
      end

      def get_sub_id!(sub_node_segment, sup_node_id)
        return nil unless valid_segment?(sub_node_segment)

        cypher_create_unique = {
          "query" => 'START sup=node({sup_node_id}) CREATE UNIQUE sup-[:NAPKIN_SUB]->(sub:NAPKIN {`napkin.segment` : {sub_node_segment}}) RETURN ID(sub)',
          "params" => {
          "sup_node_id" => sup_node_id,
          "sub_node_segment" => sub_node_segment
          }
        }
        value = cypher_query(cypher_create_unique, true)
        return value
      end

      def get_sub_id(sub_node_segment, sup_node_id)
        return nil unless valid_segment?(sub_node_segment)

        cypher_get_sub = {
          "query" => 'START sup=node({sup_node_id}) MATCH sup-[:NAPKIN_SUB]->(sub:NAPKIN) WHERE sub.`napkin.segment` = {sub_node_segment} RETURN ID(sub)',
          "params" => {
          "sup_node_id" => sup_node_id,
          "sub_node_segment" => sub_node_segment
          }
        }
        value = cypher_query(cypher_get_sub, true)
        return value
      end

      def get_sub_ids(sup_node_id)
        cypher_get_subs = {
          "query" => 'START sup=node({sup_node_id}) MATCH sup-[:NAPKIN_SUB]->(sub:NAPKIN) RETURN ID(sub)',
          "params" => {
          "sup_node_id" => sup_node_id,
          }
        }
        raw =  post(SRC, cypher_get_subs)
        sub_ids = []
        raw['data'].each do |data|
          sub_ids << data[0]
        end
        return sub_ids
      end

      def get_sub_segments(sup_node_id)
        cypher_get_subs = {
          "query" => 'START sup=node({sup_node_id}) MATCH sup-[:NAPKIN_SUB]->(sub:NAPKIN) RETURN sub.`napkin.segment` ORDER BY sub.`napkin.segment`',
          "params" => {
          "sup_node_id" => sup_node_id,
          }
        }
        raw =  post(SRC, cypher_get_subs)
        sub_segments = []
        raw['data'].each do |data|
          sub_segments << data[0]
        end
        return sub_segments
      end

      #
      # root node stuff
      #

      def check_cypher_service()
        cypher_check = false
        while(!cypher_check) do
          begin
            cypher_timestamp = {
              "query" => 'RETURN timestamp()',
              "params" => {
              }
            }
            value = cypher_query(cypher_timestamp, true)
            puts "Neo4jConnector - Neo4j cypher service ready (#{value})"
            cypher_check = true
          rescue StandardError => err
            puts "Neo4jConnector - Neo4j cypher service warming up..."
            sleep 1
          end
        end
      end

      def create_napkin_index()
        cypher_create_index = {
          "query" => 'CREATE INDEX ON :NAPKIN(`napkin.segment`)',
          "params" => {
          }
        }
        return cypher_query(cypher_create_index, true)
      end

      def create_napkin_root_constraint()
        cypher_create_root_constraint = {
          "query" => 'CREATE CONSTRAINT ON (root:NAPKIN) ASSERT root.`napkin.ROOT_NODE` IS UNIQUE',
          "params" => {
          }
        }
        return cypher_query(cypher_create_root_constraint, true)
      end

      def get_root_node_id(napkin_root_segment = "NAPKIN_ROOT//")

        cypher_create_root_node = {
          "query" => "MERGE (root:NAPKIN {`napkin.ROOT_NODE` : true}) RETURN ID(root)",
          "params" => {
          "napkin_root_segment" => napkin_root_segment
          }
        }
        root_node_id = cypher_query(cypher_create_root_node, true)
        puts "Napkin root node ID: #{root_node_id}"
        return root_node_id
      end

      #
      # Reference stuff
      #

      CREATE_UNIQUE_REF_CYPHER ='
START from_node=node({from_node_id}), to_node=node({to_node_id})
CREATE UNIQUE from_node-[r:NAPKIN_REF]->to_node
RETURN ID(r)
'

      def set_ref!(from_node_id, to_node_id)
        cypher_create_unique_ref = {
          "query" => CREATE_UNIQUE_REF_CYPHER,
          "params" => {
          "from_node_id" => from_node_id,
          "to_node_id" => to_node_id
          }
        }
        value = cypher_query(cypher_create_unique_ref, true)
        return value
      end

      def set_ref_property(key, value, ref_id)
        return nil unless valid_segment?(key)

        cypher_hash = {
          "query" => "START r=rel({ref_id}) SET r.`#{key}`={value} RETURN null",
          "params" => {
          "ref_id" => ref_id,
          "value" => value,
          }
        }
        raw = post(SRC, cypher_hash)
        return nil
      end

    end

    class SubList
      include Napkin::Util::Conversion
      def initialize(sup_node_id, neo)
        @sup_node_id = sup_node_id
        @neo = neo
      end

      NEXT_SUB_CYPHER ='
  START sup=node({sup_node_id})
  CREATE UNIQUE sup-[:NAPKIN_SUB]->
    (millions:NAPKIN {`napkin.segment` : {millions_segment}})-[:NAPKIN_SUB]->
    (thousands:NAPKIN {`napkin.segment` : {thousands_segment}})-[:NAPKIN_SUB]->
    (ones:NAPKIN {`napkin.segment` : {ones_segment}, `napkin.sublist_position` : {sublist_position}})
  RETURN ID(ones)'

      GET_SUB_CYPHER ='
  START sup=node({sup_node_id})
  MATCH sup-[:NAPKIN_SUB]->
    (millions:NAPKIN)-[:NAPKIN_SUB]->
    (thousands:NAPKIN)-[:NAPKIN_SUB]->
    (ones:NAPKIN)
  WHERE ((millions.`napkin.segment` = {millions_segment})
    AND (thousands.`napkin.segment` = {thousands_segment})
    AND (ones.`napkin.segment` = {ones_segment}))
  RETURN ID(ones)
  '

      def get_count
        sublist_count = @neo.get_node_property('napkin.sublist_count', @sup_node_id)
        return 0 if sublist_count.nil?
        return sublist_count
      end

      def next_sub_id!
        sublist_count = @neo.increment_counter('napkin.sublist_count', @sup_node_id)
        # sublist_index is zero-based storage scheme
        sublist_index = sublist_count-1
        # sublist_position is one-based for REST API
        sublist_position = sublist_count
        millions, thousands, ones = get_segment_values(sublist_index)
        cypher_hash = {
          "query" => NEXT_SUB_CYPHER,
          "params" => {
          "sup_node_id" => @sup_node_id,
          "millions_segment" => millions.to_s,
          "thousands_segment" => thousands.to_s,
          "ones_segment" => ones.to_s,
          "sublist_position" => sublist_position
          }
        }
        value = @neo.cypher_query(cypher_hash, true)
        return value
      end

      def get_sub_id(sublist_position)
        if (sublist_position.is_a? String) then
          sublist_position = parse_int(sublist_position)
        end
        return nil unless sublist_position.is_a?(Integer)
        sublist_index = sublist_position - 1
        millions, thousands, ones = get_segment_values(sublist_index)
        cypher_hash = {
          "query" => GET_SUB_CYPHER,
          "params" => {
          "sup_node_id" => @sup_node_id,
          "millions_segment" => millions.to_s,
          "thousands_segment" => thousands.to_s,
          "ones_segment" => ones.to_s
          }
        }
        value = @neo.cypher_query(cypher_hash, true)
        return value
      end

      def get_segment_values(sublist_index)
        # rollover at 1 billion
        sublist_index %= 1000000000

        millions = sublist_index / 1000000
        thousands = (sublist_index % 1000000) / 1000
        ones = sublist_index % 1000
        return millions, thousands, ones
      end

    end

  end
end