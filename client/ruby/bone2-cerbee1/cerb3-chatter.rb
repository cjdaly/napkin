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

DEVICE_ID = "cerb3"
DEVICE_DATA = {}
NAPKIN_CONFIG_URL = "http://#{DEVICE_ID}:#{DEVICE_ID}@localhost:4567/config"
NAPKIN_CHATTER_URL = "http://#{DEVICE_ID}:#{DEVICE_ID}@localhost:4567/chatter"
START_COUNT_KEY = "napkin.systems.start_count~i"

IP_LINK = 'eth0'

puts "Hello from #{DEVICE_ID}!"

CHATTER_KEY_PREFIXES = [
  "vitals.",
  "sensor.temperatureHumidity.",
  "sensor.lightSensor.",
  "sensor.barometer."
]

main_loop(false)