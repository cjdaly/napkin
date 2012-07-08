
require 'rubygems'
require 'neo4j'

class NodeFinder
	def get_sub(id, node=Neo4j.ref_node, create_if_absent=false)	
		sub = node.outgoing(:sub).find{|sub| sub[:id] == id}
		if (sub.nil? && create_if_absent) then
			sub = create_sub(id, node)
		end
		return sub
	end

	def get_sub_path(path, node=Neo4j.ref_node, create_if_absent=false)
		sub=node
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

puts "Hello"

Neo4j.ref_node.outgoing(:sub).each {|sub| puts"REF -> #{sub[:id]}"}

nf = NodeFinder.new
s1 = nf.get_sub('foo', Neo4j.ref_node, true)
s2 = nf.get_sub('bar', s1, true)
puts "#{s2[:id]}"


s3 = nf.get_sub_path(['foo','bar'])
puts "#{s3}"

s4 = nf.get_sub_path(['foo','baz'])
puts "#{s4}"

#Neo4j::Transaction.run do
#  node = Neo4j::Node.new
#  ref = Neo4j.ref_node
#  Neo4j::Relationship.new(:dudes, ref, node)
#  ref.outgoing(:dudes).each {|dude| puts"#{dude}"}
#end

puts "Goodbye"

