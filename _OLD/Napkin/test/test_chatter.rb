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
