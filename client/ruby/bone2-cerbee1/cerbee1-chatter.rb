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

  response = RestClient.post(NAPKIN_CHATTER_URL, chatter_text)
end

###

LCD_CMD_PRE = "\xfe"
LCD_CMD_CLS = "\x01"
LCD_CMD_NL = "\xc0"

def write_lcd(line1, line2)
  File.open("/dev/ttyO2", "w") do |file|
    file.write("#{LCD_CMD_PRE}#{LCD_CMD_CLS}")
    file.write(line1)
    file.write("#{LCD_CMD_PRE}#{LCD_CMD_NL}")
    file.write(line2)
  end
end

def clear_lcd()
  File.open("/dev/ttyO2", "w") do |file|
    file.write("#{LCD_CMD_PRE}#{LCD_CMD_CLS}")
  end
end

def truncate(text, length = 16)
  if (text.length >= length) then
    end_position = length - 1
    text = text[0..end_position]
  end
  return text
end

def refresh_lcd(data)
  temperature = data['sensor.temperatureHumidity.temperature~f'] || 0
  humidity = data['sensor.temperatureHumidity.relativeHumidity~f'] || 0
  brightness = data['sensor.lightSensor.lightSensorPercentage~f'] || 0
  line1 = truncate("temp: #{truncate(temperature)}")
  line2 = truncate("lite: #{truncate(brightness)}")
  write_lcd(line1, line2)
end

###

IP_LINK = 'wlan0'
IP_MATCH = /inet\s+([0-9]+\.[0-9]+)\.([0-9]+\.[0-9]+)/

def get_ip_addr()
  raw = `ip -f inet addr | grep #{IP_LINK}`
  ip_match = IP_MATCH.match(raw)
  return nil, nil if ip_match.nil?
  ip_first = ip_match.captures[0]
  ip_last = ip_match.captures[1]
  return ip_first, ip_last
end

###

IP_FIRST, IP_LAST = get_ip_addr()
puts "#{IP_LINK} IP addr: http://#{IP_FIRST}.#{IP_LAST}:4567/"

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

        refresh_lcd(DEVICE_DATA)

        sleep 3
        if (IP_FIRST.nil?) then
          write_lcd("Configure Wifi!", "login to console")
        else
          write_lcd("http://#{IP_FIRST}", ".#{IP_LAST}:4567/")
        end

      end
    end
  end
end

