require 'rubygems'
require 'sinatra'

# on pcduino:
# WARN  TCPServer Error: Address family not supported by protocol - socket(2)
# fixed (?) by:
set :bind, '0.0.0.0'

#
# plugins
require 'plugin-config'
require 'napkin-helpers'

helpers Napkin::Helpers

Napkin::Helpers::init_neo4j()
# Napkin::Helpers::start_pulse()

user = nil
use Rack::Auth::Basic, "authenticate" do |username, password|
  user = username
  auth = Napkin::Helpers::Authenticator.new
  auth.check(username,password)
end

get '/*' do |path|
  handle_request(path, request, user)
end

post '/*' do |path|
  handle_request(path, request, user)
end

put '/*' do |path|
  handle_request(path, request, user)
end

delete '/*' do |path|
  handle_request(path, request, user)
end
