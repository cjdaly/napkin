require 'rubygems'
require 'sinatra'

#
require 'napkin-server-helpers'

FeedRefresher.new

helpers NapkinServerUtils

use Rack::Auth::Basic, "authenticate" do |username, password|
  auth = Authenticator.new
  auth.check(username,password)
end

get '/feed/*' do |id|
  content_type 'text/plain'
  get_feed(id)
end

put '/feed/*' do |id|
  content_type 'text/plain'
  put_feed(id, request.body.read)
end

get '/sketchup/*/rss.xml' do |id|
  content_type 'text/xml'
  get_sketchup_channel_rss(id)
end

get '/sketchup/*/item-*.rb' do |id, item|
  content_type 'text/plain'
  get_sketchup_item_rb(id, item)
end

#def run
#  run!
#end
