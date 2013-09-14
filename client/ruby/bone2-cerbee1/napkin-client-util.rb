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

  begin
    RestClient.post(NAPKIN_CHATTER_URL, chatter_text)
  rescue StandardError => err
    puts "Error: #{err}\n#{err.backtrace}"
  end
end

###

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
def main_loop(do_write_lcd = false)
  ip_first, ip_last = get_ip_addr()
  puts "#{IP_LINK} IP addr: http://#{ip_first}.#{ip_last}:4567/"

  increment_start_count()

  File.open("/dev/ttyO1", "r") do |file|
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
        DEVICE_DATA[key] = value
        if ((key == "state.vitalsAndSensorsUpdated") && (value == "true")) then
          chatter_sensor_data(DEVICE_DATA)

          if (do_write_lcd) then
            refresh_lcd(DEVICE_DATA)

            sleep 3

            if (IP_FIRST.nil?) then
              write_lcd("Configure Wifi!", "login to console")
            else
              write_lcd("http://#{ip_first}", ".#{ip_last}:4567/")
            end
          end

        end
      end
    end
  end
end
