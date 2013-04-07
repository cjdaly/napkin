require 'json'
require 'rubygems'
require 'rest_client'

SR = "http://localhost:7474/db/data"
SRN = SR + "/node"
SRB = SR + "/batch"
SRC = SR + "/cypher"

# TODO: batch operations!

def neo4j_get(url, key=nil)
  response = RestClient.get(url)
  response_hash = JSON.parse(response.to_s)
  if (key.nil?) then
    return response_hash
  else
    return response_hash[key]
  end
end

def neo4j_post(url, json)
  response = RestClient.post(url, json, :content_type=>:json, :accept=>:json)
  puts "RESPONSE: #{response}"
  return response.to_s
end

def neo4j_get_reference_node()
  ref_node_url1 = neo4j_get(SR, "reference_node")
  puts "REF_NODE: #{ref_node_url1}"

  ref_node_url2 = neo4j_get(SR)["reference_node"]
  puts "REF_NODE: #{ref_node_url2}"

  response = neo4j_get(ref_node_url1)
end

rn = neo4j_get_reference_node
puts rn["properties"]

json_create_ref = {
  "to" => "#{SRN}/1",
  "type" => "SUB",
  "data" => {
  "napkin.test.foo" => "FOO"
  }
}.to_json
# neo4j_post("#{SRN}/0/relationships", json_create_ref)

json_batch_create_sub = [
  {
  "id" => 0,
  "method" => "POST",
  "to" => "/node",
  "body" => {
  "napkin.test.foo" => "FOO"
  }
  } ,
  {
  "id" => 1,
  "method" => "POST",
  "to" => "/node/0/relationships",
  "body" => {
  "to" => "#{SRN}/{0}",
  "type" => "SUB",
  "data" => {
  "napkin.test.bar" => "BAR"
  }
  }
  } ,
].to_json

# puts json_batch_create_sub
# neo4j_post(SRB, json_batch_create_sub)

json_cypher = {
  "query" => "start n=node(1) return n.`napkin.test.foo`",
  "params" => {
  "x" => "y"
  }
}.to_json
puts json_cypher
neo4j_post(SRC, json_cypher)

