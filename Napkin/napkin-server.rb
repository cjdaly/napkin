require 'napkin-config'

puts "data_path=#{Napkin::Config::DATA_PATH}"

#
require 'rubygems'
require 'sinatra'

#
# heartbeat
require 'napkin-pulse'

#
# extensions
require 'napkin-ext-tracker'
require 'napkin-ext-sketchup'
require 'napkin-ext-chatter'
require 'napkin-ext-config'

#
require 'napkin-server-utils'

helpers Napkin::ServerUtils

Napkin::ServerUtils.init_neo4j

pulse = Napkin::Core::Pulse.new
pulse.cycle

user = nil
use Rack::Auth::Basic, "authenticate" do |username, password|
  user = username
  auth = Napkin::ServerUtils::Authenticator.new
  auth.check(username,password)
end

get '/*' do |path|
  handle_request(path, :get, request, user)
end

post '/*' do |path|
  handle_request(path, :post, request, user)
end

put '/*' do |path|
  handle_request(path, :put, request, user)
end
