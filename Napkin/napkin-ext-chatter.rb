require 'yaml'
require 'rss/2.0'

#
require 'rubygems'
require 'neo4j'

#
require 'napkin-config'
require 'napkin-node-util'
require 'napkin-handlers'
require 'napkin-extensions'

module Napkin
  module Handlers
    class ChatterPostHandler < HttpMethodHandler
      def handle
        return "" unless at_destination?
        post_time = Time.now

        @request.body.rewind
        body_text = @request.body.read

        puts "CHATTER got from #{@user}:\n#{body_text}"

        nn = @nn.dup
        nn.go_sub!(@user)
        nn.set_key_prefix('chatter')

        post_count = nn.increment('post_count')

        nn.go_sub!("#{post_count}")
        nn['post_body'] = body_text
        nn['post_time_i'] = post_time.to_i
        nn['post_time_s'] = post_time.to_s

        return "OK"
      end
    end
  end

  module Extensions
    module Tasks
      class ChatterTask < Task
        def init
          super
          puts "!!! ChatterTask.init called !!!"
          init_nodes
        end

        def init_nodes
          nn = Napkin::NodeUtil::NodeNav.new
          nn.go_sub_path!('chatter')
          nn[NAPKIN_HTTP_POST] = "ChatterPostHandler"
        end

        def cycle
          super
          puts "!!! ChatterTask.cycle called !!!"
          # TODO: first level analysis
        end
      end
    end
  end
end