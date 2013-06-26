####
# Copyright (c) 2013 Chris J Daly (github user cjdaly)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   cjdaly - initial API and implementation
####
require 'rubygems'
require 'sinatra'

# on pcduino:
# WARN  TCPServer Error: Address family not supported by protocol - socket(2)
# fixed (?) by:
set :bind, '0.0.0.0'

#
# helpers
require 'napkin-helpers'

helpers Napkin::Helpers
Napkin::Helpers::init_system_config()
Napkin::Helpers::init_neo4j()

#
# plugins
require 'plugin-chatter'
require 'plugin-config'
require 'plugin-vitals'
require 'plugin-times'
# require 'plugin-TEMPLATE'

Napkin::Helpers::init_plugins()

#
# pulse
Napkin::Helpers::start_pulse()

user = nil
use Rack::Auth::Basic, "authenticate" do |username, password|
  user = username
  auth = Napkin::Helpers::Authenticator.new
  auth.check(username,password)
end

get '/*' do |path|
  handle_request(path, user)
end

post '/*' do |path|
  handle_request(path, user)
end

put '/*' do |path|
  handle_request(path, user)
end

delete '/*' do |path|
  handle_request(path, user)
end
