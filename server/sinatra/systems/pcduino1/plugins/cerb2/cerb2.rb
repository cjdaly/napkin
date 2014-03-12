####
# Copyright (c) 2014 Chris J Daly (github user cjdaly)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   cjdaly - initial API and implementation
####

module Napkin::Plugins
  class Cerb2 < PluginBase
    DEVICE_ID = "cerb2"
    CHATTER_KEY_PREFIXES = [
      "vitals.",
      "sensor.gasSense.",
      "sensor.barometer."
    ]

    def init
      # service_node_id = init_service_segment
      register_task('cerb2_sensor_data', SensorData_Task)
      puts "In Cerb2.init() !!!"
    end

    class SensorData_Task < Napkin::Tasks::ActiveTaskBase
      include Napkin::Util::Client
      def init
        puts "In Cerb2.SensorData_Task.init() !!!"
        @sensor_uart = File.open("/dev/ttyS1", "r")
        @sensor_data = {}
        increment_start_count(DEVICE_ID)
      end

      def fini
        puts "In Cerb2.SensorData_Task.fini() !!!"
        @sensor_uart.close
      end

      def cycle
        process_sensor_data(@sensor_uart, @sensor_data, DEVICE_ID, CHATTER_KEY_PREFIXES)
      end

    end
  end
end