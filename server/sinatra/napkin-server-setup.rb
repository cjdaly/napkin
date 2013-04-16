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

def napkin_post(url, body_text)
  response = RestClient.post(url, body_text, {:params => {'sub' => sub_id}})
  puts "RESPONSE: #{response}"
  return response.to_s
end

config_url = "http://test:test@localhost:4567/config"
# response = RestClient.post(config_url, "", {:params => {'sub' => 'foo'}})
# foo_url = config_url + "/test?key=foo"
# response = RestClient.put(foo_url, "Hello World!")

tasks_url = "http://test:test@localhost:4567/napkin/tasks"
# test_task = RestClient.post(tasks_url, "", {:params => {'sub' => 'test'}})
