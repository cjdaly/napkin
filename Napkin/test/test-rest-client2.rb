require 'yaml'
require 'rubygems'
require 'rest_client'

def put_node(path, property_hash, hostname="localhost", creds="fred:fred")
  yaml = YAML.dump(property_hash)
  puts "PUT Outgoing:\n#{yaml}\n"

  response = RestClient.put("http://#{creds}@#{hostname}:4567/#{path}", yaml)
  puts "PUT Incoming:\n#{response.to_s()}\n"
end

def post_node(path, property_hash, hostname="localhost", creds="fred:fred")
  yaml = YAML.dump(property_hash)
  puts "POST Outgoing:\n#{yaml}\n"

  response = RestClient.post("http://#{creds}@#{hostname}:4567/#{path}", yaml)
  puts "POST Incoming:\n#{response.to_s()}\n"
end

props = {
  'name' =>"Hello",
  'quest' => "???"
}
post_node('test/a/b', props)