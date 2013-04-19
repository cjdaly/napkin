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
require 'json'
require 'rubygems'
require 'rest_client'

SR = "http://localhost:7474/db/data"
SRN = SR + "/node"
SRB = SR + "/batch"
SRC = SR + "/cypher"

def napkin_post(url, body_text, params = {})
  response = RestClient.post(url, body_text, {:params => params})
  puts "RESPONSE: #{response}"
end

def napkin_put(url, body_text, params = {})
  response = RestClient.put(url, body_text, {:params => params})
  puts "RESPONSE: #{response}"
end

## config
#config_url = "http://test:test@localhost:4567/config"
#response = napkin_post(config_url, "", {'sub' => 'test'})
#
#foo_url = config_url + "/test"
#response = napkin_put(foo_url, "Hello World!", {'key' => 'foo'})

## chatter
chatter_url = "http://test:test@localhost:4567/chatter"
response = napkin_post(chatter_url, "foo=X\nbar=yyy\nbaz=hello")

