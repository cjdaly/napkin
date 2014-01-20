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

require 'rest_client'

module Napkin::Plugins
  class Cerb3 < PluginBase
    DEVICE_ID = "cerb3"
    NAPKIN_CONFIG_URL = "http://#{DEVICE_ID}:#{DEVICE_ID}@localhost:4567/config"
    NAPKIN_CHATTER_URL = "http://#{DEVICE_ID}:#{DEVICE_ID}@localhost:4567/chatter"
    START_COUNT_KEY = "napkin.systems.start_count~i"
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
      def init
        puts "In Cerb3.SensorData_Task.init() !!!"
        @sensor_uart = File.open("/dev/ttyO1", "r")
        @sensor_data = nil
      end

      def fini
        puts "In Cerb3.SensorData_Task.fini() !!!"
        @sensor_uart.close
      end

      def cycle
        line = @sensor_uart.gets
        if (!line.nil? && line.include?('=')) then
          key, value = line.split('=', 2)
          if (@sensor_data.nil?) then
            if ((key == "state.vitalsAndSensorsUpdated") && (value == "false")) then
              @sensor_data = {}
            end
          else
            if ((key == "state.vitalsAndSensorsUpdated") && (value == "true")) then
              chatter_sensor_data(@sensor_data)
              @sensor_data = nil
            else
              @sensor_data[key] = value
            end
          end
        end
      end

      #
      # TODO: move to common/shared 'util' module
      #

      def increment_start_count()
        # create config area for device (if absent)
        RestClient.post(NAPKIN_CONFIG_URL, "", {:params => {'sub' => DEVICE_ID}})

        # get current start_count
        device_config_url = "#{NAPKIN_CONFIG_URL}/#{DEVICE_ID}"
        start_count_text = RestClient.get(device_config_url, {:params => {'key' => START_COUNT_KEY}})
        start_count = parse_int(start_count_text) || 0

        # increment and put value back to server config
        start_count += 1
        RestClient.put(device_config_url, start_count.to_s, {:params => {'key' => START_COUNT_KEY}})
        puts "#{DEVICE_ID} starts: #{start_count}"
      end

      def parse_int(text)
        return nil if text.nil?
        begin
          return Integer(text)
        rescue ArgumentError => err
          return nil
        end
      end

      def chatter_sensor_data(data)
        chatter_text = ""
        data.keys.each do |key|
          CHATTER_KEY_PREFIXES.each do |prefix|
            if (key.start_with?(prefix)) then
              chatter_text << "#{key} = #{data[key]}\n"
            end
          end
        end

        begin
          RestClient.post(NAPKIN_CHATTER_URL, chatter_text)
        rescue StandardError => err
          puts "Error: #{err}\n#{err.backtrace}"
        end
      end

    end
  end
end
