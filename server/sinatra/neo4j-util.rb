require 'rubygems'
require 'rest_client'
require 'json'

module Napkin
  module Neo4jUtil
    SR = "http://localhost:7474/db/data"
    SRN = SR + "/node"
    SRB = SR + "/batch"
    SRC = SR + "/cypher"
    #
    def Neo4jUtil.node_url(node_id)
      return "#{SRN}/#{node_id}"
    end

    def Neo4jUtil.node_properties_url(node_id)
      return "#{SRN}/#{node_id}/properties"
    end

    def Neo4jUtil.get(url)
      response = RestClient.get(url, :accept=>:json)
      response_json_object = JSON.parse(response.to_s)
      return response_json_object
    end

    def Neo4jUtil.post(url, json_object)
      json = json_object.to_json
      response = RestClient.post(url, json, :content_type=>:json, :accept=>:json)
      response_json_object = JSON.parse(response.to_s)
      return response_json_object
    end

    def Neo4jUtil.get_properties(node_id)
      return Neo4jUtil.get("#{SRN}/#{node_id}/properties")
    end

    def Neo4jUtil.get_properties_text(node_id)
      node_properties = Neo4jUtil.get_properties(node_id)

      properties_text = "ID=#{node_id}\n"
      node_properties.each do |key, value|
        properties_text << "#{key}=#{value}\n"
      end
      return properties_text
    end

    def Neo4jUtil.get_property(key, node_id)
      return nil unless Neo4jUtil.valid_segment?(key)

      cypher_get_property = {
        "query" => "START n=node({node_id}) RETURN n.`#{key}`?",
        "params" => {
        "node_id" => node_id,
        }
      }
      raw = Neo4jUtil.post(SRC, cypher_get_property)
      return Neo4jUtil.extract_cypher_result(raw['data'])
    end

    def Neo4jUtil.set_property(key, value, node_id)
      return nil unless Neo4jUtil.valid_segment?(key)

      cypher_set_property = {
        "query" => "START n=node({node_id}) SET n.`#{key}`={value} RETURN null",
        "params" => {
        "node_id" => node_id,
        "value" => value,
        }
      }
      raw = Neo4jUtil.post(SRC, cypher_set_property)
      return nil
    end

    def Neo4jUtil.increment_counter(key, node_id)
      return nil unless Neo4jUtil.valid_segment?(key)

      cypher_increment_counter = {
        "query" => "START n=node({node_id}) SET n.`#{key}` = COALESCE(n.`#{key}`?, 0) + 1 RETURN n.`#{key}`",
        "params" => {
        "node_id" => node_id,
        }
      }
      raw = Neo4jUtil.post(SRC, cypher_increment_counter)
      return Neo4jUtil.extract_cypher_result(raw['data'])
    end

    def Neo4jUtil.next_sub_id!(sup_node_id)
      sub_count = Neo4jUtil.increment_counter('napkin.sub_count', sup_node_id)
      return nil if sub_count.nil?
      sub_node_id =  Neo4jUtil.get_sub_id!(sub_count.to_s, sup_node_id)
      Neo4jUtil.set_property('napkin.position', sub_count, sub_node_id)
      return sub_node_id
    end

    SEGMENT_MATCH = /^[-_.a-zA-Z0-9]+$/

    def Neo4jUtil.valid_segment?(node_segment)
      return false if node_segment.nil?
      return false unless node_segment.is_a? String
      match = SEGMENT_MATCH.match(node_segment)
      return !match.nil?
    end

    def Neo4jUtil.get_sub_id!(sub_node_segment, sup_node_id)
      return nil unless Neo4jUtil.valid_segment?(sub_node_segment)

      cypher_create_unique = {
        "query" => 'START sup=node({sup_node_id}) CREATE UNIQUE sup-[:SUB]->(sub {`napkin.segment` : {sub_node_segment}}) RETURN ID(sub)',
        "params" => {
        "sup_node_id" => sup_node_id,
        "sub_node_segment" => sub_node_segment
        }
      }
      raw = Neo4jUtil.post(SRC, cypher_create_unique)
      return Neo4jUtil.extract_cypher_result(raw['data'])
    end

    def Neo4jUtil.get_sub_id(sub_node_segment, sup_node_id)
      return nil unless Neo4jUtil.valid_segment?(sub_node_segment)

      cypher_get_sub = {
        "query" => 'START sup=node({sup_node_id}) MATCH sup-[:SUB]->sub WHERE sub.`napkin.segment`! = {sub_node_segment} RETURN ID(sub)',
        "params" => {
        "sup_node_id" => sup_node_id,
        "sub_node_segment" => sub_node_segment
        }
      }
      raw =  Neo4jUtil.post(SRC, cypher_get_sub)
      return extract_cypher_result(raw['data'])
    end

    def Neo4jUtil.get_root_node_id()
      return Neo4jUtil.get_sub_id!('ROOT', 0)
    end

    #internal helpers

    def Neo4jUtil.extract_cypher_result(raw_data)
      if (raw_data.length == 1) then
        data_item = raw_data[0]
        if ((data_item.is_a? Array) && (data_item.length == 1)) then
          return data_item[0]
        end
      end
      return nil
    end

  end
end