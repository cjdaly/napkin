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
#
# Example usage:
#   jruby --server -J-Xms32M -J-Xmx32M cerbee1-chatter.rb
##

require 'rest_client'

DEVICE_ID = "cerbee1"
DEVICE_DATA = {}
NAPKIN_CONFIG_URL = "http://#{DEVICE_ID}:#{DEVICE_ID}@localhost:4567/config"
NAPKIN_CHATTER_URL = "http://#{DEVICE_ID}:#{DEVICE_ID}@localhost:4567/chatter"
START_COUNT_KEY = "napkin.systems.start_count~i"

puts "Hello from #{DEVICE_ID}!"

CHATTER_KEY_PREFIXES = [
  "vitals.",
  "sensor.temperatureHumidity.",
  "sensor.lightSensor."
]

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
  puts "Starts: #{start_count}"
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

  puts "CHATTER:\n#{chatter_text}\n"
  response = RestClient.post(NAPKIN_CHATTER_URL, chatter_text)
end

###

increment_start_count()

File.open("/dev/ttyO1", "r") do |file|
  while(line = file.gets)
    next if line.nil?
    key, value = line.split('=', 2)
    if (!value.nil?) then
      key.strip! ; value.strip!
      DEVICE_DATA[key] = value
      if ((key == "state.vitalsAndSensorsUpdated") && (value == "true")) then
        chatter_sensor_data(DEVICE_DATA)
      end
    end
  end
end

