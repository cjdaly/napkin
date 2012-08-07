require 'yaml'
require 'rubygems'
require 'neo4j'

module Napkin
  module NodeUtil
    class PropertyWrapper
      attr_accessor :id, :description, :default
      def initialize(id, description, default)
        @id = id
        @description = description
        @default = default
        @converter_hash = {}
      end

      def add_converter(id, converter_lambda)
        @converter_hash[id] = converter_lambda
        return self
      end

      def convert(id, param)
        converter_lambda = @converter_hash[id]
        result = ""
        if (!converter_lambda.nil?) then
          begin
            result = converter_lambda.call(param)
          rescue StandardError => err
            result = "Error in refresh_feed: #{err}\n#{err.backtrace}"
            puts result
          end
        end
        return result
      end

    end

    class PropertyGroup
      def initialize(id, prefix=id, separator='.')
        @id = id
        @prefix = prefix
        @separator = separator
        @wrapper_id_list = []
        @wrapper_hash = {}
      end

      def prefix_key(key)
        "#{@prefix}#{@separator}#{key}"
      end

      def add_property(id, description = "", default = nil)
        @wrapper_id_list.push(id)
        @wrapper_hash[id] = PropertyWrapper.new(id, description, default)
      end

      def add_converter(property_id, converter_id, converter_lambda)
        wrapper = @wrapper_hash[property_id]
        if (!wrapper.nil?) then
          wrapper.add(converter_id, converter_lambda)
        end
      end

      def yaml_to_hash(yaml_text)
        yaml = YAML.load(yaml_text)
        out = {}
        @wrapper_id_list.each do |id|
          val = yaml[id]
          if (!val.nil?) then
            out[id] = val
          end
        end
        return out
      end

      def hash_to_yaml(hash)
        return YAML.dump(hash)
      end

      def node_to_hash(node)
        hash = {}
        @wrapper_id_list.each do |id|
          hash[id] = node[prefix_key(id)]
        end
        return hash
      end

      def hash_to_node(node, hash)
        Neo4j::Transaction.run do
          @wrapper_id_list.each do |id|
            node[prefix_key(id)] = hash[id]
          end
        end
      end

      def dump_hash(hash)
        result = ""
        @wrapper_id_list.each do |id|
          wrapper = @wrapper_hash[id]
          value = hash[id]
          result += "~~~ #{id}=[#{value.class}, default: #{wrapper.default}]= #{value}\n"
        end
        return result
      end

      def construct_hash(converter_id, param)
        hash = {}
        @wrapper_id_list.each do |id|
          wrapper = @wrapper_hash[id]
          hash[id] = wrapper.convert(converter_id, param)
        end
        return hash
      end

    end
  end
end

g = Napkin::NodeUtil::PropertyGroup.new("stuff")

g.add_property('a',"Hello",0).
add_converter('test',lambda {|x|"#{x}"})

g.add_property('b',"World",'foo').
add_converter('test',lambda {|x|"#{x}!!!"})

h = {
  'a' => 7,
  'b' => 'Foooooo',
  'c' => "..."
}
puts g.dump_hash(h)

h2 = g.construct_hash('test',"wow")
puts g.hash_to_yaml(h2)
