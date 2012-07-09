require 'yaml'
require 'rubygems'
require 'rest_client'

# response = RestClient.get 'http://localhost:4567/foo.txt'
# puts response.to_str

def put_feed(id, feed_hash)
  yaml = YAML.dump(feed_hash)
  puts "Outgoing:\n#{yaml}"
  
  response = RestClient.put("http://fred:fred@localhost:4567/feed/#{id}", yaml)
  puts "Incoming:"
  puts response.to_s()
end

zh = {
  'name' =>"Zerohedge",
  'url' => "http://www.zerohedge.com/fullrss2.xml",
  'refresh_enabled' => true,
  'refresh_in_minutes' => 60
}
put_feed('zh', zh)

zh2 = {
  'name' =>"Zerohedge (FeedBurner)",
  'url' => "http://feeds.feedburner.com/zerohedge/feed?format=xml",
  'refresh_enabled' => true,
  'refresh_in_minutes' => 20
}
put_feed('zh2', zh2)
