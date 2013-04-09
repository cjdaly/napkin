require 'json'
require 'rubygems'
require 'rest_client'

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
      puts "NEO4J GET: #{url}"

      response = RestClient.get(url, :accept=>:json)

      puts response.to_s

      response_json_object = JSON.parse(response.to_s)
      return response_json_object
    end

    def Neo4jUtil.post(url, json_object)
      puts "NEO4J POST: #{url}"

      json = json_object.to_json
      response = RestClient.post(url, json, :content_type=>:json, :accept=>:json)

      puts response.to_s

      response_json_object = JSON.parse(response.to_s)
      return response_json_object
    end

    def Neo4jUtil.get_sub!(sub_node_segment, sup_node_id = 0)
      cypher_create_unique = {
        "query" => 'START sup=node({sup_node_id}) CREATE UNIQUE sup-[:SUB]->(sub {`napkin.segment` : {sub_node_segment}}) RETURN ID(sub)',
        "params" => {
        "sup_node_id" => sup_node_id,
        "sub_node_segment" => sub_node_segment
        }
      }
      return Neo4jUtil.post(SRC, cypher_create_unique)
    end

    def Neo4jUtil.get_sub(sub_node_segment, sup_node_id = 0)
      cypher_get_sub = {
        "query" => 'START sup=node({sup_node_id}) MATCH sup-[:SUB]->sub WHERE sub.`napkin.segment`! = {sub_node_segment} RETURN ID(sub)',
        "params" => {
        "sup_node_id" => sup_node_id,
        "sub_node_segment" => sub_node_segment
        }
      }
      return Neo4jUtil.post(SRC, cypher_get_sub)
    end

  end
end