require 'napkin-config'

puts "data_path=#{Napkin::Config::DATA_PATH}"

#
require 'rubygems'
require 'sinatra'

#
require 'napkin-server-helpers'
require 'napkin-tracker'

helpers Napkin::ServerUtils

tracker = Napkin::ServerUtils::Tracker2.new
tracker.cycle

use Rack::Auth::Basic, "authenticate" do |username, password|
  auth = Napkin::ServerUtils::Authenticator.new
  auth.check(username,password)
end

#get '/feed/*' do |id|
#  content_type 'text/plain'
#  get_feed(id)
#end
#
#put '/feed/*' do |id|
#  content_type 'text/plain'
#  put_feed(id, request.body.read)
#end
#
#get '/sketchup/*/rss.xml' do |id|
#  content_type 'text/xml'
#  get_sketchup_channel_rss(id)
#end
#
#get '/sketchup/*/item-*.rb' do |id, item|
#  content_type 'text/plain'
#  get_sketchup_item_rb(id, item)
#end

#
#

get '/*' do |path|
  handle_request(path, :get, request)
end

post '/*' do |path|
  handle_request(path, :post, request)
end

put '/*' do |path|
  handle_request(path, :put, request)
end
