NAPKIN_DATA_PATH=File.expand_path("../../Napkin-Data")
puts "NAPKIN_DATA_PATH=#{NAPKIN_DATA_PATH}"
#
require 'rubygems'

#
require 'neo4j'

Neo4j::Config[:storage_path] = NAPKIN_DATA_PATH + "/neo4j-db"

require 'open-uri/cached'

OpenURI::Cache.cache_path = NAPKIN_DATA_PATH + "/open-uri-cache"

def git_config(name, value)
  result_text = `git config --global #{name} "#{value}"`
  result_status = $?
  puts "CONFIG(git): #{name}=#{value} -> #{result_status}\n#{result_text}"
end

git_config("user.name", "Dude")
git_config("user.email", "dude@example.com")
