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

        query_text = @request.query_string
        query_hash = CGI.parse(query_text)

        param_format = query_hash['format'].first
        if (param_format.nil? || param_format=="") then
          param_format = "raw"
        end

        @request.body.rewind
        body_text = @request.body.read

        puts "CHATTER got from #{@user}"

        nn = @nn.dup
        nn.go_sub!(@user)
        nn.set_key_prefix('chatter')

        post_count = nn.increment('post_count')

        nn.go_sub!("#{post_count}")
        nn.set_key_prefix("chatter.post","~")

        nn['time_i'] = post_time.to_i
        nn['time_s'] = post_time.to_s
        nn['format'] = param_format

        if(param_format == "keyset") then
          nn.set_key_prefix("","")
          parse_keyset(body_text, nn)
        else
          nn['body'] = body_text
        end

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