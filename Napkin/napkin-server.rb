require 'napkin-config'

puts "data_path=#{Napkin::Config::DATA_PATH}"

#
require 'rubygems'
require 'sinatra'

#
require 'napkin-server-helpers'

#require 'napkin-tracker'
require 'napkin-pulse'

helpers Napkin::ServerUtils

Napkin::ServerUtils.init_neo4j

# tracker = Napkin::Tracker.new
# tracker.cycle
pulse = Napkin::Core::Pulse.new
pulse.cycle

use Rack::Auth::Basic, "authenticate" do |username, password|
  auth = Napkin::ServerUtils::Authenticator.new
  auth.check(username,password)
end

get '/*' do |path|
  handle_request(path, :get, request)
end

post '/*' do |path|
  handle_request(path, :post, request)
end

put '/*' do |path|
  handle_request(path, :put, request)
end
