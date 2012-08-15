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

#props_zh = {
#  'id' => "zh",
#  'name' =>"Zerohedge",
#  'url' => "http://www.zerohedge.com/fullrss2.xml",
#  'refresh_enabled' => true,
#  'refresh_frequency_minutes' => 30
#}

props_zh = {
  'id' => "zh",
  'name' =>"Zerohedge",
  'url' => "http://feeds.feedburner.com/zerohedge/feed?format=xml",
  'refresh_enabled' => true,
  'refresh_frequency_minutes' => 25
}

props_jesse = {
  'id' => "jesse",
  'name' =>"Jesse's Café Américain",
  'url' => "http://feeds.feedburner.com/JessesCafeAmericain?format=xml",
  'refresh_enabled' => true,
  'refresh_frequency_minutes' => 30
}

props_google_news = {
  'id' => "gn",
  'name' =>"Google News",
  'url' => "http://news.google.com/news?pz=1&cf=all&ned=us&hl=en&output=rss",
  'refresh_enabled' => true,
  'refresh_frequency_minutes' => 20
}

post_node('tracker/feed', props_zh)
post_node('tracker/feed', props_jesse)
post_node('tracker/feed', props_google_news)
