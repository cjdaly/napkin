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
  class Cerb3 < PluginBase
    def init
      # service_node_id = init_service_segment
      register_task('cerb3_sensor_data', SensorData_Task)
      puts "In Cerb3.init() !!!"
    end

    class SensorData_Task < Napkin::Tasks::ActiveTaskBase
      def init
        puts "In Cerb3.SensorData_Task.init() !!!"
        @sensor_data = File.open("/dev/ttyO1", "r")
      end

      def fini
        puts "In Cerb3.SensorData_Task.fini() !!!"
        @sensor_data.close
      end

      def cycle
        line = file.gets
        if (line.nil?) then
          puts "Cerb3 - nil"
        elsif (!line.include?('=')) then
          puts "Cerb3 - line: #{line}"
        else
          key, value = line.split('=', 2)
          puts "Cerb3 - key: #{key}, value: #{value}"
        end
      end
    end
  end
end
