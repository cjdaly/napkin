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

module Napkin
  module Util
    module Conversion
      def parse_int(text)
        return nil if text.nil?
        begin
          return Integer(text)
        rescue ArgumentError => err
          return nil
        end
      end

      def parse_float(text)
        return nil if text.nil?
        begin
          return Float(text)
        rescue ArgumentError => err
          return nil
        end
      end
    end

    module Client
      require 'rest_client'
      include Conversion

      START_COUNT_KEY = "napkin.systems.start_count~i"

      #
      def get_chatter_url(device_id)
        return "http://#{device_id}:#{device_id}@localhost:4567/chatter"
      end

      def get_config_url(device_id)
        return "http://#{device_id}:#{device_id}@localhost:4567/config"
      end

      def increment_start_count(device_id)
        # create config area for device (if absent)
        config_url = get_config_url(device_id)
        RestClient.post(config_url, "", {:params => {'sub' => device_id}})

        # get current start_count
        device_config_url = "#{config_url}/#{device_id}"
        start_count_text = RestClient.get(device_config_url, {:params => {'key' => START_COUNT_KEY}})
        start_count = parse_int(start_count_text) || 0

        # increment and put value back to server config
        start_count += 1
        RestClient.put(device_config_url, start_count.to_s, {:params => {'key' => START_COUNT_KEY}})
        puts "#{device_id} starts: #{start_count}"
      end

      def chatter_sensor_data(data, device_id, key_prefix_filter)
        chatter_text = ""
        data.keys.each do |key|
          key_prefix_filter.each do |prefix|
            if (key.start_with?(prefix)) then
              chatter_text << "#{key} = #{data[key]}\n"
            end
          end
        end

        begin
          RestClient.post(get_chatter_url(device_id), chatter_text)
        rescue StandardError => err
          puts "Error: #{err}\n#{err.backtrace}"
        end
      end

      def process_sensor_data(sensor_uart, sensor_data)
        line = sensor_uart.gets
        if (!line.nil? && line.include?('=')) then
          key, value = line.split('=', 2)
          key.strip! ; value.strip!
          if (sensor_data.nil?) then
            if ((key == "state.vitalsAndSensorsUpdated") && (value == "false")) then
              sensor_data = {}
            end
          else
            if ((key == "state.vitalsAndSensorsUpdated") && (value == "true")) then
              if (sensor_data["state.vitalsAndSensorsUpdated"] == "false") then
                chatter_sensor_data(sensor_data, DEVICE_ID, CHATTER_KEY_PREFIXES)
              end
              sensor_data.clear
            else
              sensor_data[key] = value
            end
          end
        end
      end

    end

  end
end
