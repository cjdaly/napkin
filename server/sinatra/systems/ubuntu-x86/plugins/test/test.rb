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

module Napkin::Plugins
  class Test < PluginBase
    def init
      service_node_id = init_service_segment
      register_task('test', Test_Task)
      puts "In Test.init() !!!"
    end

    class Test_Task < Napkin::Tasks::ActiveTaskBase
      def init
        @doit_count = 0
        @cycle_count = 0
        puts "In Test_Task.init() !!!"
      end

      def todo?
        return true
      end

      def doit
        @doit_count += 1
        puts "In Test_Task.doit() !!!  doit_count: #{@doit_count}"
        if (@doit_count == 1000) then
          napkin_driver.restart("Test_Task: initiating system restart!!!")
        end
      end

      def cycle
        @cycle_count += 1
        puts "In Test_Task.cycle() !!! cycle_count: #{@cycle_count}"
        sleep 2
      end

      def fini
        puts "In Test_Task.fini() !!!"
      end

    end
  end
end
