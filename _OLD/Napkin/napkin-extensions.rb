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
require 'rubygems'
require 'neo4j'

module Napkin

  # TODO: bad hash ...
  NAPKIN_ID = 'napkin#id'
  NAPKIN_SUB = 'napkin#sub'
  NAPKIN_REF = 'napkin#ref'
  #
  # TODO: bad hash slash ...
  NAPKIN_HTTP_HANDLERS = 'napkin/http/handlers'
  NAPKIN_HTTP_GET = NAPKIN_HTTP_HANDLERS + '#get'
  NAPKIN_HTTP_POST = NAPKIN_HTTP_HANDLERS + '#post'
  NAPKIN_HTTP_PUT = NAPKIN_HTTP_HANDLERS + '#put'
  #
  NAPKIN_TASK_INIT = 'napkin/tasks/task#init'
  #
  module Extensions
    class Task
      def initialize(task_node, cycle_node, start_node)
        @task_node = task_node
        @cycle_node = cycle_node
        @start_node = start_node
      end

      def get_node_ids
        return "task: #{@task_node[NAPKIN_ID]}, cycle: #{@cycle_node[NAPKIN_ID]}, start: #{@start_node[NAPKIN_ID]}"
      end

      def init
        puts "!!! Task.init called (#{get_node_ids}) !!!"
      end

      def cycle
        puts "!!! Task.cycle called (#{get_node_ids}) !!!"
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