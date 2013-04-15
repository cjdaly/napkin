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
require 'rest_client'

def post_chatter(
  user,
  message,
  hostname="localhost",
  creds="#{user}:#{user}@",
  port=":4567"
  )

  puts "CHATTER #{user}:\n#{message}\n"

  response = RestClient.post("http://#{creds}#{hostname}#{port}/chatter", message)
  puts "CHATTER response:\n#{response.to_s()}\n"
end

post_chatter("thelma", "Hello!")
