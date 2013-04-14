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
      # TODO: validate key as segment
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
      # TODO: validate key as segment
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
      value = Neo4jUtil.get_property(key, node_id)

      if (value.nil?) then
        value = 0
      end

      if (value.is_a? Numeric) then
        value += 1
        Neo4jUtil.set_property(key, value, node_id)
      else
        value = nil
      end

      return value
    end

    def Neo4jUtil.next_sub_id!(sup_node_id)
      sub_count = Neo4jUtil.increment_counter('napkin.sub_count', sup_node_id)
      return nil if sub_count.nil?
      return Neo4jUtil.get_sub_id!(sub_count.to_s, sup_node_id)
    end

    def Neo4jUtil.get_sub_id!(sub_node_segment, sup_node_id)
      # TODO: validate sub_node_segment
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
      # TODO: validate sub_node_segment
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