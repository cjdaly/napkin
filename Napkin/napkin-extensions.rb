require 'rubygems'
require 'neo4j'

module Napkin

  NAPKIN_ID = 'napkin#id'
  NAPKIN_SUB = 'napkin#sub'
  NAPKIN_REF = 'napkin#ref'
  #
  NAPKIN_HTTP_HANDLERS = 'napkin/http/handlers'
  NAPKIN_HTTP_GET = NAPKIN_HTTP_HANDLERS + '#get'
  NAPKIN_HTTP_POST = NAPKIN_HTTP_HANDLERS + '#post'
  NAPKIN_HTTP_PUT = NAPKIN_HTTP_HANDLERS + '#put'
  #
  module Extensions
    class Task
      def init
        @is_initialized = true
        puts "!!! Task.init called !!!"
      end

      def cycle
        if (!@is_initialized)
          init
        end

        puts "!!! Task.cycle called !!!"
      end

      def get_progress
        return 0
      end

      def get_progress_max
        return 1
      end
    end

    module Tasks
      class NilTask < Task
      end
    end

    class Adornment # see PropertyGroup
      class Property # see PropertyWrapper
      end
    end

    class HttpHandler # see HttpMethodHandler
    end
  end
end