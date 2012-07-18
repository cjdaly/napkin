require 'yaml'
require 'rss/2.0'

#
require 'rubygems'
require 'neo4j'
require 'open-uri/cached'

#
#
class PropertyMapper
  def initialize(keys)
    @keys=keys
  end

  def get_hash_for(node)
    hash = {}
    @keys.each do |key|
      hash[key] = node[key]
    end
    return hash
  end

  def yaml_to_hash(yaml_text)
    yaml = YAML.load(yaml_text)
    out = {}
    @keys.each do |key|
      val = yaml[key]
      if (!val.nil?) then
        out[key] = val
      end
    end
    return out
  end

  def hash_to_yaml(hash)
    return YAML.dump(hash)
  end

  def adorn_node(node, hash)
    Neo4j::Transaction.run do
      @keys.each do |key|
        node[key] = hash[key]
      end
    end
  end
end

#
#
class NodeFinder
  def get_sub(id, node=Neo4j.ref_node, create_if_absent=false)
    sub = node.outgoing(:sub).find{|sub| sub[:id] == id}
    if (sub.nil? && create_if_absent) then
      sub = create_sub(id, node)
    end
    return sub
  end

  def get_sub_path(path, create_if_absent=false)
    sub=Neo4j.ref_node
    path.each do |id|
      sub = get_sub(id, sub, create_if_absent)
      puts "got #{sub} for #{id}"
      break if sub.nil?
    end
    return sub
  end

  def create_sub(id, node)
    sub=nil
    Neo4j::Transaction.run do
      sub = node.outgoing(:sub).find{|sub| sub[:id] == id}
      if (sub.nil?) then
        sub = Neo4j::Node.new :id => id
        node.outgoing(:sub) << sub
      end
    end
    return sub
  end
end

