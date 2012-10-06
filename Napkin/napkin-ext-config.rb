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
    class ConfigPostHandler < HttpMethodHandler
      def handle
        return "" unless at_destination?

        query_text = @request.query_string
        query_hash = CGI.parse(query_text)

        param_sub = query_hash['sub'].first
        return "ConfigPostHandler: missing 'sub' param!" if (param_sub.nil? || param_sub=="")

        nn = @nn.dup
        if (nn.go_sub!(param_sub)) then
          nn[NAPKIN_HTTP_POST] = "ConfigPostHandler"
          nn[NAPKIN_HTTP_PUT] = "ConfigPutHandler"
          nn[NAPKIN_HTTP_GET] = "ConfigGetHandler"
        end

        return "OK"
      end
    end

    class ConfigPutHandler < HttpMethodHandler
      def handle
        return "" unless at_destination?

        query_text = @request.query_string
        query_hash = CGI.parse(query_text)

        param_key = query_hash['key'].first
        return "ConfigPutHandler: missing 'key' param!" if (param_key.nil? || param_key=="")

        @request.body.rewind
        body_text = @request.body.read

        nn = @nn.dup
        old_value = nn["config/data##{param_key}"]
        nn["config/data##{param_key}"] = body_text

        old_value="" if old_value.nil?
        return old_value.to_s
      end
    end

    class ConfigGetHandler < HttpMethodHandler
      def handle
        return "" unless at_destination?

        query_text = @request.query_string
        query_hash = CGI.parse(query_text)

        param_key = query_hash['key'].first
        if (param_key.nil? || param_key=="") then
          return super
        end

        nn = @nn.dup
        value = nn["config/data##{param_key}"]

        value="" if value.nil?
        return value.to_s
      end
    end
  end

  module Extensions
    module Tasks
      class ConfigTask < Task
        def init
          super
          puts "!!! ConfigTask.init called !!!"
          init_nodes
        end

        def init_nodes
          nn = Napkin::NodeUtil::NodeNav.new
          nn.go_sub_path!('config')
          nn[NAPKIN_HTTP_POST] = "ConfigPostHandler"
        end

        def cycle
          super
          puts "!!! ConfigTask.cycle called !!!"
          # TODO: first level analysis?
        end
      end
    end
  end
end
