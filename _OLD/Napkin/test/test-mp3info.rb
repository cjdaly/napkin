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
require 'rubygems'
require 'mp3info'

MUSIC_ROOT = "/media/napkin-media/music"

path = MUSIC_ROOT + "/Pink Floyd/Dark Side Of The Moon/04 The Great Gig In The Sky.mp3"

puts "Hello!"

dirs = Dir[MUSIC_ROOT + '/**/']
dirs.each { |dir|
  puts ">> " + dir
}

Mp3Info.open(path) do |mp3|
  puts mp3.tag.title
  puts mp3.tag.artist
  puts mp3.tag.album
  puts mp3.tag.tracknum
  puts mp3.length
end