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
require 'napkin-neo4j'
require 'napkin-handlers'
require 'napkin-util'

module Napkin
  module Tasks
    class TaskBase
      include Napkin::Util::Conversion
      def initialize(plugin)
        @plugin = plugin
        @task_initialized = false
        @task_finalized = false
      end

      def get_plugin(id = nil)
        return @plugin.get_plugin(id)
      end

      def napkin_driver
        return @plugin.napkin_driver
      end

      def neo
        return @plugin.neo
      end

      def init?
        return @task_initialized
      end

      def init!
        @task_initialized = true
      end

      def fini!
        @task_finalized = true
      end

      def fini?
        return @task_finalized
      end

      def active?
        return false
      end

      #
      # override below in subclass
      #

      def init
      end

      def todo?
        return false
      end

      def doit
      end

      def fini
      end

    end

    class ActiveTaskBase < TaskBase
      def active?
        return true
      end

      def init!
        @finished = false
        @enabled = true
        @thread = Thread.new do
          while(@enabled) do
            begin
              cycle
            rescue StandardError => err
              puts "Error in active task thread: #{err}\n#{err.backtrace}"
            end
            sleep 0
          end
          @finished = true
        end
        super
      end

      def fini!
        @enabled = false
        while(!@finished)
          sleep 1
        end
        super
      end

      #
      # override below in subclass
      #

      def cycle
      end

    end

  end

end