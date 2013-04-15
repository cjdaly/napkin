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
require 'sinatra'
require 'neo4j'

DATA_PATH = File.expand_path("../../Test-Data")
Neo4j::Config[:storage_path] = DATA_PATH + "/neo4j-db"

foo = Neo4j.ref_node['foo']
puts "!!! #{foo} -> #{Neo4j.ref_node['foo']}"

def worker_thread(name, delay = 3)
  thread = Thread.new do
    begin
      while (true)
        sleep delay
        v = Neo4j.ref_node[name]

        Neo4j::Transaction.run do
          Neo4j.ref_node[name] = "#{name} ... #{v}"
        end

        puts "!!! #{v} -> #{Neo4j.ref_node[name]}"
      end
    rescue StandardError => err
      puts "Error in thread - #{name}: #{err}\n#{err.backtrace}"
    end
  end
end

worker_thread('dude',3)
worker_thread('dood',4)
worker_thread('dooooood',5)
worker_thread('d00d',6)

def handle_request(path, request)
  content_type 'text/plain'
  "Hello!  #{path} ... #{Neo4j.ref_node[path]}"
end

get '/*' do |path|
  handle_request(path, request)
end
