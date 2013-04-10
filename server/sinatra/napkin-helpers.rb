require 'json'
require 'neo4j-util'

module Napkin
  module Helpers
    Neo = Napkin::Neo4jUtil
    
    def Helpers.init_neo4j()
      puts "init_neo4j!"
      napkin_id = Neo.get_sub_id!('napkin')
      starts_id = Neo.get_sub_id!('starts', napkin_id)
      cycles_id = Neo.get_sub_id!('cycles', napkin_id)
      
      start_count = Neo.increment_counter('napkin.starts.count', starts_id)
      puts "STARTS: #{start_count}"
    end
    
    def handle_request (path, request, user)
      content_type 'text/plain'
      segments = path.split('/')
      
      current_segment_index = 0
      current_node_id = 0
      segments.each_with_index do |segment, i|
        next if segment.to_s.empty?
        
        sub_node_id = Neo.get_sub_id(segment, current_node_id)
        if (!sub_node_id.nil?) then
          current_node_id = sub_node_id
          puts "SUB: #{segment} : #{current_node_id} in #{path}"
        else
          puts "No SUB: #{segment} in #{path}"
        end
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
