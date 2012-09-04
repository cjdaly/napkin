require 'rubygems'
require 'neo4j'

module Napkin
  module Extensions
    class Task
      def init
        puts "!!! Task.init called !!!"
      end

      def cycle
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