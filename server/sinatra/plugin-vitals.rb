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
require 'neo4j-util'
require 'napkin-tasks'
require 'napkin-handlers'

module Napkin
  module Tasks
    class Napkin_VitalsTask < TaskBase
      def init
        napkin_node_id = Neo.pin(:napkin)
        vitals_id = Neo.get_sub_id!('vitals', napkin_node_id)
        Neo.set_property('napkin.handlers.POST.class_name', 'Napkin_VitalsGetHandler', vitals_id)
      end

      def todo?
        return false
      end

      def doit
      end
    end
  end

  module Handlers
    class Napkin_VitalsGetHandler < HandlerBase
      def handle
        puts "Napkin_VitalsGetHandler!!!"
      end
    end
  end
end
