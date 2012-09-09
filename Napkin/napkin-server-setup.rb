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
  'tracker/feeds/feed#name' =>"Zerohedge",
  'tracker/feeds/feed#url' => "http://feeds.feedburner.com/zerohedge/feed?format=xml",
  'tracker/feeds/feed#refresh_enabled' => true,
  'tracker/feeds/feed#refresh_frequency_minutes' => 25
}

props_jesse = {
  'id' => "jesse",
  'tracker/feeds/feed#name' =>"Jesse's Café Américain",
  'tracker/feeds/feed#url' => "http://feeds.feedburner.com/JessesCafeAmericain?format=xml",
  'tracker/feeds/feed#refresh_enabled' => true,
  'tracker/feeds/feed#refresh_frequency_minutes' => 30,
  'tracker/feeds/feed#last_refresh_time_i' => 0
}

props_google_news = {
  'id' => "gn",
  'tracker/feeds/feed#name' =>"Google News",
  'tracker/feeds/feed#url' => "http://news.google.com/news?pz=1&cf=all&ned=us&hl=en&output=rss",
  'tracker/feeds/feed#refresh_enabled' => true,
  'tracker/feeds/feed#refresh_frequency_minutes' => 20
}

# post_node('tracker/feeds', props_zh)
# post_node('tracker/feeds', props_jesse)
post_node('tracker/feeds', props_google_news)

tasks_test = {
  'id' => "test",
  'napkin/tasks#task_name' =>"test task",
  'napkin/tasks#task_class' => "TestTask",
  'napkin/tasks#task_enabled' => true
}
tasks_tracker = {
  'id' => "tracker",
  'napkin/tasks#task_name' =>"RSS tracker task",
  'napkin/tasks#task_class' => "TrackerTask",
  'napkin/tasks#task_enabled' => true
}

#post_node('napkin/tasks', tasks_test)
#post_node('napkin/tasks', tasks_tracker)

