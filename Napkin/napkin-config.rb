module Napkin
  module Config
    DATA_PATH = File.expand_path("../../Napkin-Data")
    NEO4J_PATH = DATA_PATH + "/neo4j-db"
    OPEN_URI_CACHE_PATH = DATA_PATH + "/open-uri-cache"

    ROOT_URL = "http://localhost:4567"
  end
end

require 'fileutils'

#
require 'rubygems'

#
require 'neo4j'

FileUtils.mkpath(Napkin::Config::NEO4J_PATH)
Neo4j::Config[:storage_path] = Napkin::Config::NEO4J_PATH

require 'open-uri/cached'

FileUtils.mkpath(Napkin::Config::OPEN_URI_CACHE_PATH)
OpenURI::Cache.cache_path = Napkin::Config::OPEN_URI_CACHE_PATH