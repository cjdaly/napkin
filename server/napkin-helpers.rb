require 'json'
require 'neo4j-util'

module Napkin
  module Helpers
    Neo = Napkin::Neo4jUtil
    
    def Helpers.init_neo4j()
      puts "init_neo4j!"
      Neo.get_sub!('test')
    end
    
    def handle_request (path, request, user)
      content_type 'text/plain'
      segments = path.split('/')
      
      current_segment_index = 0
      segments.each_with_index do |segment, i|
        next if segment.to_s.empty?
        
        Neo.get_sub(segment)
        
      end
      
      
      response_text = "#{path} #{request.request_method} #{user}\n"
      return response_text
    end

    class Authenticator
      def check(username, password)
        return username == password
      end
    end
  end
end
