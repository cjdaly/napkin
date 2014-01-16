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
      include ConversionUtil
      def initialize(plugin)
        @plugin = plugin
        @task_initialized = false
      end

      def get_plugin(id = nil)
        return @plugin.get_plugin(id)
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

    end
  end

end