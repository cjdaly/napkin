require 'yaml'
require 'rubygems'
require 'rest_client'

def put_node(
  path,
  property_hash,
  hostname="localhost",
  creds="fred:fred@",
  port=":4567"
  )
  yaml = YAML.dump(property_hash)
  puts "PUT Outgoing:\n#{yaml}\n"

  response = RestClient.put("http://#{creds}#{hostname}#{port}/#{path}", yaml)
  puts "PUT Incoming:\n#{response.to_s()}\n"
end

def post_node(
  path,
  property_hash,
  hostname="localhost",
  creds="fred:fred@",
  port=":4567"
  )
  yaml = YAML.dump(property_hash)
  puts "POST Outgoing:\n#{yaml}\n"

  response = RestClient.post("http://#{creds}#{hostname}#{port}/#{path}", yaml)
  puts "POST Incoming:\n#{response.to_s()}\n"
end

props_zh = {
  'id' => "zh",
  'name' =>"Zerohedge",
  'url' => "http://www.zerohedge.com/fullrss2.xml",
  'refresh_enabled' => true,
  'refresh_in_minutes' => 20
}

props_zh2 = {
  'id' => "zh2",
  'name' =>"Zerohedge (FeedBurner)",
  'url' => "http://feeds.feedburner.com/zerohedge/feed?format=xml",
  'refresh_enabled' => true,
  'refresh_in_minutes' => 20
}

props_jesse = {
  'id' => "jesse",
  'name' =>"Jesse's Café Américain",
  'url' => "http://feeds.feedburner.com/JessesCafeAmericain?format=xml",
  'refresh_enabled' => true,
  'refresh_in_minutes' => 20
}

post_node('tracker/feed', props_jesse)
