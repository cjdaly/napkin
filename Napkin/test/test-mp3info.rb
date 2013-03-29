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