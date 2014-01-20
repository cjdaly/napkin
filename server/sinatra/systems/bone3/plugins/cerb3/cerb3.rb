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
    DEVICE_ID = "cerb3"
    CHATTER_KEY_PREFIXES = [
      "vitals.",
      "sensor.temperatureHumidity.",
      "sensor.lightSensor.",
      "sensor.barometer."
    ]

    #
    def init
      # service_node_id = init_service_segment
      register_task('cerb3_sensor_data', SensorData_Task)
      puts "In Cerb3.init() !!!"
    end

    class SensorData_Task < Napkin::Tasks::ActiveTaskBase
      include Napkin::Util::Client
      def init
        puts "In Cerb3.SensorData_Task.init() !!!"
        @sensor_uart = File.open("/dev/ttyO1", "r")
        @sensor_data = {}
        increment_start_count(DEVICE_ID)
      end

      def fini
        puts "In Cerb3.SensorData_Task.fini() !!!"
        @sensor_uart.close
      end

      def cycle
        process_sensor_data(@sensor_uart, @sensor_data)
      end

    end
  end
end
