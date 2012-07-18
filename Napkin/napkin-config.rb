module Napkin
  module Config
    DATA_PATH = File.expand_path("../../Napkin-Data")

    ROOT_URL = "http://localhost:4567"
  end
end

#
require 'rubygems'

#
require 'neo4j'

Neo4j::Config[:storage_path] = Napkin::Config::DATA_PATH + "/neo4j-db"

require 'open-uri/cached'

OpenURI::Cache.cache_path = Napkin::Config::DATA_PATH + "/open-uri-cache"
