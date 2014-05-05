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

### IP address

IP_LINK = 'wlan0'
IP_MATCH = /inet\s+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/

def get_ip_addr()
  raw = `ip -f inet addr | grep #{IP_LINK}`
  ip_match = IP_MATCH.match(raw)
  return nil if ip_match.nil?
  ip_addr = ip_match.captures[0]
  return ip_addr
end

### LCD util

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

def parse_float(text)
  return nil if text.nil?
  begin
    return Float(text)
  rescue ArgumentError => err
    return nil
  end
end

def refresh_lcd(sensor_data, ip_addr)

  temperature = sensor_data['sensor.temperatureHumidity.temperature~f']
  tempC = parse_float(temperature)
  if (tempC.nil?) then
    write_lcd("temperature", "?")
  else
    tempF = tempC * 1.8 + 32.0
    write_lcd("temperature", "#{tempF.round(2)}F / #{tempC.round(2)}C")
  end

  sleep 2

  humidity = sensor_data['sensor.temperatureHumidity.relativeHumidity~f']
  humi = parse_float(humidity)
  if (humi.nil?) then
    write_lcd("humidity", "?")
  else
    write_lcd("humidity", "#{humi.round(2)}%")
  end

  sleep 2

  lightness = sensor_data['sensor.lightSensor.lightSensorPercentage~f']
  lite = parse_float(lightness)
  if (lite.nil?) then
    write_lcd("lightness", "?")
  else
    write_lcd("lightness", "#{lite.round(2)}%")
  end

  sleep 2

  write_lcd("IP address", ip_addr)
end

###

SENSOR_UART = "/dev/ttyO1"

def main_loop()
  ip_addr = get_ip_addr()
  puts "IP address: #{ip_addr}"

  sensor_data = { }

  File.open(SENSOR_UART, "r") do |file|
    while(line = file.gets)
      next if line.nil?
      key = nil; value = nil
      begin
        key, value = line.split('=', 2)
      rescue StandardError => err
        puts "Error: #{err}\n#{err.backtrace}"
      end
      if (!value.nil?) then
        key.strip! ; value.strip!
        sensor_data[key] = value
        if (key == "state.vitalsAndSensorsUpdated") then
          if (value == 'false') then
            sensor_data = { }
          else
            refresh_lcd(sensor_data, ip_addr)
          end
        end
      end
    end
  end
end

main_loop()
