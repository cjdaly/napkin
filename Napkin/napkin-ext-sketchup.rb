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
    class SketchupModelsPostHandler < HttpMethodHandler
      def handle
        return "" unless at_destination?
        post_time = Time.now

        @request.body.rewind
        body_text = @request.body.read

        puts "Sketchup Model post from #{@user}:\n#{body_text}"

        nn = @nn.dup
        nn.set_key_prefix('sketchup/models')
        
        post_count = nn.increment('post_count')

        nn.go_sub!("#{post_count}")
        nn['post_body'] = body_text
        nn['post_user'] = @user
        nn['post_time_i'] = post_time.to_i
        nn['post_time_s'] = post_time.to_s
        nn['state'] = 'new'

        return "OK"
      end
    end
  end

  module Extensions
    module Tasks
      class SketchupTask < Task
        def init
          super
          puts "!!! SketchupTask.init called !!!"
          init_nodes
        end

        def init_nodes
          nn = Napkin::NodeUtil::NodeNav.new
          nn.go_sub_path!('sketchup/models')
          nn[NAPKIN_HTTP_POST] = "SketchupModelsPostHandler"

          # nn.reset
          # nn.go_sub_path!('sketchup/fragments')
          # nn[NAPKIN_HTTP_POST] = "SketchupComposePostHandler"
        end

        def cycle
          super
          puts "!!! SketchupTask.cycle called !!!"
          # refresh_feeds
        end
      end
    end
  end
end