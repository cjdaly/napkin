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

require 'napkin-client-util'

DEVICE_ID = "cerbee1"
DEVICE_DATA = {}
NAPKIN_CONFIG_URL = "http://#{DEVICE_ID}:#{DEVICE_ID}@localhost:4567/config"
NAPKIN_CHATTER_URL = "http://#{DEVICE_ID}:#{DEVICE_ID}@localhost:4567/chatter"
START_COUNT_KEY = "napkin.systems.start_count~i"

IP_LINK = 'wlan0'

puts "Hello from #{DEVICE_ID}!"

CHATTER_KEY_PREFIXES = [
  "vitals.",
  "sensor.temperatureHumidity.",
  "sensor.lightSensor."
]

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
  else
    text = text.rjust(length)
  end
  return text
end

def refresh_lcd(data)
  temperature = data['sensor.temperatureHumidity.temperature~f'] || 0
  temp = truncate(temperature.to_s, 5)

  humidity = data['sensor.temperatureHumidity.relativeHumidity~f'] || 0
  humi = truncate(humidity.to_s, 5)

  brightness = data['sensor.lightSensor.lightSensorPercentage~f'] || 0
  lite = truncate(brightness.to_s, 4)

  line1 = "temp :humi :lite"
  line2 = "#{temp}:#{humi}:#{lite}"
  write_lcd(line1, line2)
end

###

main_loop(true)

