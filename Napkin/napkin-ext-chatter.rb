require 'yaml'
require 'rss/2.0'
require 'cgi'

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

        puts "CHATTER got from #{@user}"

        nn = @nn.dup
        nn.go_sub!(@user)
        nn.set_key_prefix('chatter')

        post_count = nn.increment('post_count')

        nn.go_sub!("#{post_count}")
        nn.set_key_prefix("chatter.post","~")
        nn['body'] = body_text
        nn['time_i'] = post_time.to_i
        nn['time_s'] = post_time.to_s

        nn.set_key_prefix("","")
        parse_keyset(body_text, nn)

        return "OK"
      end

      def parse_keyset(keyset_text, nn)
        keyset_text.each_line do |line|
          key, value = line.split('=', 2)
          if (!key.nil?) then
            key = key.strip
            value = value.strip
            puts "KEY: " + key + ", VAL: " + value
            nn[key] = value
          end
        end
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