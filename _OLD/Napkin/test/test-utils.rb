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
require 'date'
require 'rubygems'
require 'neo4j'
require 'napkin-config'
require 'napkin-node-util'

def stuff

  nn = Napkin::NodeUtil::NodeNav.new
  result = nn.go_sub('feed')
  puts "#{result} / #{nn.node[:id]} //// #{nn[:id]}"

  result = nn.go_sub!('wow')
  puts "#{result} / #{nn.node[:id]}"

  puts "foo.bar: #{nn['foo.bar']}"
  nn.init_property('foo.bar',"bye")

  result = nn.go_sup
  puts "#{result} / #{nn.node[:id]}"

  result = nn.go_sub!('fun')
  puts "#{result} / #{nn.node[:id]} // #{nn.get_path}"

  result = nn.go_sub('dude')
  puts "#{result} / #{nn.node[:id]}"

  nn = Napkin::NodeUtil::NodeNav.new
  result = nn.go_sub_path("foo/bar/baz")
  puts "#{result} / #{nn.get_path}"

  result = nn.go_sub_path!("foo/bar/baz")
  puts "#{result} / #{nn.get_path}"

  nn = Napkin::NodeUtil::NodeNav.new
  result = nn.go_sub_path("foo/bar/baz")
  puts "#{result} / #{nn.get_path}"

  result = nn.get_or_init('test.blah',"Hello!")
  puts "#{result} / #{nn.get_path}"

  result = nn['test.blah', 'bye']
  puts "#{result} / #{nn.get_path}"

end

def more_stuff
  nn = Napkin::NodeUtil::NodeNav.new

  result = nn.go_sub_path!("test/stuff/i2")
  puts "#{result} / #{nn.get_path}"

  t = Time.now

  (0...10).each do |i|
    result = nn.go_sub!(i)
    puts "#{result} / #{nn.get_path}"

    ti = (t + (i*60)).to_i
    result = nn.get_or_init('time', ti)
    puts "#{result} .. #{nn['time']} .. #{Time.at(nn['time'])} // #{nn.get_path}"

    nn.go_sup()
  end

  f = nn.node.outgoing(:sub).find_all{|sub| (sub[:id] > 3) && (sub[:id] <= 6)}
  g = f.sort {|x,y| x[:id] <=> y[:id] }
  g.each do |n|
    puts "!!! #{n[:id]} // #{n['time']} // #{Time.at(n['time'])}"
  end

end

def double_stuff
  nn = Napkin::NodeUtil::NodeNav.new

  result = nn.go_sub('tracker')
  puts "#{result} / #{nn.get_path}"

  nn.reset
  result = nn.go_sub_path('tracker/cycle')
  puts "#{result} / #{nn.get_path} // #{nn['cycle_count']}"

  result = nn['cycle_count'] = 1
  puts "#{result} / #{nn.get_path} // #{nn['cycle_count']}"

end

def time_stuff
  t = Time.now

  puts "time: #{t}, to_i: #{t.to_i}"
end

time_stuff()
