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

def put_config(
  path,
  key,
  value,
  hostname="localhost",
  creds="fred:fred@",
  port=":4567"
  )
  #
  response = RestClient.put(
  "http://#{creds}#{hostname}#{port}/config/#{path}",
  value,
  {:params => {'key' => key}}
  )
  #
  puts "PUT Incoming:\n#{response.to_s()}\n"
end

def post_config(
  path,
  sub_id,
  hostname="localhost",
  creds="fred:fred@",
  port=":4567"
  )
  #
  response = RestClient.post(
  "http://#{creds}#{hostname}#{port}/config/#{path}",
  "",
  {:params => {'sub' => sub_id}}
  )
  #
  puts "POST Incoming:\n#{response.to_s()}\n"
end


#
# Tasks
#

tasks_test = {
  'napkin#id' => "test",
  'napkin/tasks#task_name' =>"test task",
  'napkin/tasks#task_class' => "TestTask",
  'napkin/tasks#task_enabled' => true
}
tasks_tracker = {
  'napkin#id' => "tracker",
  'napkin/tasks#task_name' =>"RSS feed tracker task",
  'napkin/tasks#task_class' => "TrackerTask",
  'napkin/tasks#task_enabled' => true
}
tasks_sketchup = {
  'napkin#id' => "sketchup",
  'napkin/tasks#task_name' =>"Sketchup model construction",
  'napkin/tasks#task_class' => "SketchupTask",
  'napkin/tasks#task_enabled' => true
}
tasks_chatter = {
  'napkin#id' => "chatter",
  'napkin/tasks#task_name' =>"Chatter",
  'napkin/tasks#task_class' => "ChatterTask",
  'napkin/tasks#task_enabled' => true
}
tasks_config = {
  'napkin#id' => "config",
  'napkin/tasks#task_name' =>"Device configuration",
  'napkin/tasks#task_class' => "ConfigTask",
  'napkin/tasks#task_enabled' => true
}

# post_node('napkin/tasks', tasks_test)
# post_node('napkin/tasks', tasks_tracker)
# post_node('napkin/tasks', tasks_sketchup)
# post_node('napkin/tasks', tasks_chatter)
# post_node('napkin/tasks', tasks_config)


#
# Keysets
#

keysets_test = {
  'napkin#id' => "test",
  'napkin/keysets#keyset_name' =>"test keyset",
  'napkin/keysets#keyset_description' =>"blah blah blah...",
  'napkin/keysets#keyset_index_id' =>"???"
}

# post_node('keysets', keysets_test)


#
# Config
#

# post_config('', 'ndp1')
# put_config('ndp1', 'blinkM_13_hsb', "0,255,42")
# put_config('ndp1', 'blinkM_14_hsb', "80,255,42")
# put_config('ndp1', 'blinkM_15_hsb', "160,255,42")
# put_config('ndp1', 'device_location', "man cave")

# post_config('', 'cerb1')
# put_config('cerb1', 'device_location', "man cave")
# put_config('cerb1', 'MulticolorLed_rBg', "0,16,16")
# put_config('cerb1', 'post_cycle', "50")
# put_config('cerb1', 'cycle_delay_milliseconds', "5000")

# post_config('', 'cerb2')
# put_config('cerb2', 'device_location', "man cave")
# put_config('cerb2', 'button_led', "off")
# put_config('cerb2', 'post_cycle', "60")
# put_config('cerb2', 'cycle_delay_milliseconds', "5000")

# post_config('', 'cerbee1')
# put_config('cerbee1', 'device_location', "garage")
# put_config('cerbee1', 'post_cycle', "60")
# put_config('cerbee1', 'cycle_delay_milliseconds', "5000")

# post_config('', 'cerbee2')
# put_config('cerbee2', 'device_location', "man cave")
# put_config('cerbee2', 'post_cycle', "60")
# put_config('cerbee2', 'cycle_delay_milliseconds', "5000")

# post_config('', 'bone1')
# put_config('bone1', 'device_location', "tv room")
# put_config('bone1', 'test', "foobar")
# put_config('bone1', 'status', 126.chr + " hello " + 127.chr)

#
# Sketchup
#

sketchup_test1 = {
  'napkin#id' => "test1",
  'sketchup.models~title' =>"Sketchup Test Model",
  'sketchup.models~kind' =>"top"
}
sketchup_test1_timeline = {
  'napkin#id' => "timeline",
  'sketchup.models~title' =>"Timeline",
  'sketchup.models~kind' =>"timeline"
}
sketchup_test1_dataline = {
  'napkin#id' => "dataline",
  'sketchup.models~title' =>"Data",
  'sketchup.models~kind' =>"dataline"
}
# post_node('sketchup/models', sketchup_test1)
# post_node('sketchup/models/test1', sketchup_test1_timeline)
# post_node('sketchup/models/test1', sketchup_test1_dataline)

#
# Tracker
#

props_zh = {
  'napkin#id' => "zh",
  'tracker/feeds/feed#name' =>"Zerohedge",
  'tracker/feeds/feed#url' => "http://feeds.feedburner.com/zerohedge/feed?format=xml",
  # alternate url:
  # 'tracker/feeds/feed#url' => "http://www.zerohedge.com/fullrss2.xml",
  'tracker/feeds/feed#refresh_enabled' => true,
  'tracker/feeds/feed#refresh_frequency_minutes' => 55
}

props_jesse = {
  'napkin#id' => "jesse",
  'tracker/feeds/feed#name' =>"Jesse's Café Américain",
  'tracker/feeds/feed#url' => "http://feeds.feedburner.com/JessesCafeAmericain?format=xml",
  'tracker/feeds/feed#refresh_enabled' => true,
  'tracker/feeds/feed#refresh_frequency_minutes' => 150,
  # 'tracker/feeds/feed#last_refresh_time_i' => 0
}

props_krugman = {
  'napkin#id' => "krugman",
  'tracker/feeds/feed#name' =>"Paul Krugman",
  'tracker/feeds/feed#url' => "http://krugman.blogs.nytimes.com/feed",
  'tracker/feeds/feed#refresh_enabled' => true,
  'tracker/feeds/feed#refresh_frequency_minutes' => 115
}

props_google_news = {
  'napkin#id' => "gn",
  'tracker/feeds/feed#name' =>"Google News",
  'tracker/feeds/feed#url' => "http://news.google.com/news?pz=1&cf=all&ned=us&hl=en&output=rss",
  'tracker/feeds/feed#refresh_enabled' => true,
  'tracker/feeds/feed#refresh_frequency_minutes' => 20
}

# post_node('tracker/feeds', props_zh)
# post_node('tracker/feeds', props_jesse)
# post_node('tracker/feeds', props_krugman)
# post_node('tracker/feeds', props_google_news)

