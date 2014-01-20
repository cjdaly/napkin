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
  DEVICE_ID = "cerbee1"
  CHATTER_KEY_PREFIXES = [
    "vitals.",
    "sensor.temperatureHumidity.",
    "sensor.lightSensor."
  ]

  #
  class Cerbee1 < PluginBase
    def init
      # service_node_id = init_service_segment
      register_task('cerbee1_sensor_data', SensorData_Task)
      puts "In Cerbee1.init() !!!"
    end

    class SensorData_Task < Napkin::Tasks::ActiveTaskBase
      include Napkin::Util::Client
      def init
        puts "In Cerbee1.SensorData_Task.init() !!!"
        @sensor_uart = File.open("/dev/ttyO1", "r")
        @sensor_data = nil
        increment_start_count(DEVICE_ID)
      end

      def fini
        puts "In Cerbee1.SensorData_Task.fini() !!!"
        @sensor_uart.close
      end

      def cycle
        line = @sensor_uart.gets
        if (!line.nil? && line.include?('=')) then
          key, value = line.split('=', 2)
          key.strip! ; value.strip!
          if (@sensor_data.nil?) then
            if ((key == "state.vitalsAndSensorsUpdated") && (value == "false")) then
              @sensor_data = {}
            end
          else
            if ((key == "state.vitalsAndSensorsUpdated") && (value == "true")) then
              chatter_sensor_data(@sensor_data, DEVICE_ID, CHATTER_KEY_PREFIXES)
              @sensor_data = nil
            else
              @sensor_data[key] = value
            end
          end
        end
      end

    end

  end
end
