require 'yaml'
require 'rubygems'
require 'neo4j'

#
require 'napkin-config'

module Napkin
  module NodeUtil
    #
    #
    class NodeNav
      attr_accessor :node, :property_key_prefix, :property_key_prefix_separator
      def initialize(node = Neo4j.ref_node)
        @node = node
        @property_key_prefix = ""
        @property_key_prefix_separator = ""
      end

      def reset(node = Neo4j.ref_node)
        @node = node
        @property_key_prefix = ""
        @property_key_prefix_separator = ""
      end

      def prefix_key(key)
        "#{@property_key_prefix}#{@property_key_prefix_separator}#{key}"
      end

      def set_key_prefix(prefix, separator = "#")
        @property_key_prefix = prefix
        @property_key_prefix_separator = separator
      end

      def [](key)
        return @node[prefix_key(key)]
      end

      def []=(key, value)
        Neo4j::Transaction.run do
          @node[prefix_key(key)] = value
        end
      end

      def init_property(key, default)
        property_initialized = true
        Neo4j::Transaction.run do
          if (@node[prefix_key(key)].nil?) then
            @node[prefix_key(key)] = default
          else
            property_initialized = false
          end
        end
        return property_initialized
      end

      def get_or_init(key, default)
        value = @node[prefix_key(key)]
        if (value.nil?) then
          Neo4j::Transaction.run do
            value = @node[prefix_key(key)]
            if (value.nil?) then
              @node[prefix_key(key)] = default
              value = default
            end
          end
        end
        return value
      end

      def go_sub(id)
        sub = @node.outgoing(:sub).find{|sub| sub[:id] == id}
        if (sub.nil?) then
          return false
        else
          @node = sub
          return true
        end
      end

      def go_sub!(id)
        created_node = false
        if (!go_sub(id)) then
          Neo4j::Transaction.run do
            sub = @node.outgoing(:sub).find{|sub| sub[:id] == id}
            if (sub.nil?) then
              sub = Neo4j::Node.new :id => id
              @node.outgoing(:sub) << sub
              created_node = true
            end
            @node = sub
          end
        end
        return created_node;
      end

      def go_sub_path(path)
        path_segments = path.split('/')

        missed_count = path_segments.length
        path_segments.each do |segment|
          if (go_sub(segment)) then
            missed_count -= 1
          else
            break;
          end
        end

        return missed_count
      end

      def go_sub_path!(path, set_property_key_prefix = false)
        if (set_property_key_prefix) then
          @property_key_prefix = path
          @property_key_prefix_separator = "#"
        end

        path_segments = path.split('/')
        sub_exists = true

        created_count = 0
        path_segments.each do |segment|
          if(go_sub!(segment)) then
            created_count += 1
          end
        end

        return created_count
      end

      def go_sup
        sup = @node.incoming(:sub).first()
        if (sup.nil?) then
          return false
        else
          @node = sup
          return true
        end
      end

      def get_path
        nn = dup
        path = "#{nn.get_segment}"
        while (nn.go_sup())
          path = "#{nn.get_segment}/" + path
        end
        return path
      end

      def get_segment
        segment = @node[:id]
        segment.nil? ? 'nil' : segment
      end
    end

    #
    #

    class PropertyWrapper
      attr_accessor :id, :description, :default, :group
      def initialize(id, description, default, group)
        @id = id
        @description = description
        @default = default
        @group = group
        @converter_hash = {}
      end

      def add_converter(id, converter_lambda)
        @converter_hash[id] = converter_lambda
        return @group
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
      def initialize(id, separator='#')
        @id = id
        @separator = separator
        @wrapper_id_list = []
        @wrapper_hash = {}
      end

      def prefix_key(key)
        "#{@id}#{@separator}#{key}"
      end

      def read(node, key)
        return node[prefix_key(key)]
      end

      def add_property(id, description = "", default = nil)
        @wrapper_id_list.push(id)
        @wrapper_hash[id] = PropertyWrapper.new(id, description, default, self)
      end

      def add_converter(property_id, converter_id, converter_lambda)
        wrapper = @wrapper_hash[property_id]
        if (!wrapper.nil?) then
          wrapper.add(converter_id, converter_lambda)
        end
      end

      def yaml_to_hash(yaml_text, filter = true, output_hash = {})
        yaml = YAML.load(yaml_text)
        return yaml unless filter

        @wrapper_id_list.each do |id|
          val = yaml[prefix_key(id)]
          if (!val.nil?) then
            output_hash[prefix_key(id)] = val
          end
        end
        return output_hash
      end

      def hash_to_yaml(hash)
        return YAML.dump(hash)
      end

      def node_to_hash(node)
        hash = {}
        @wrapper_id_list.each do |id|
          hash[prefix_key(id)] = node[prefix_key(id)]
        end
        return hash
      end

      def hash_to_node(node, hash)
        Neo4j::Transaction.run do
          @wrapper_id_list.each do |id|
            old_value = node[prefix_key(id)]
            new_value = hash[prefix_key(id)]
            if (old_value != new_value) then
              if (new_value.nil?) then
                # leave node value as-is
                # TODO: how to express removal of node property?
              elsif (old_value.nil?) then
                node[prefix_key(id)] = new_value
                puts "hash_to_node: DEFINED value:#{prefix_key(id)}"
              else
                node[prefix_key(id)] = new_value
                puts "hash_to_node: CHANGED value:#{prefix_key(id)}"
                puts "#{old_value}"
                puts "-->"
                puts "#{new_value}"
                puts "--!"
              end
            end
          end
        end
      end

      def dump_hash(hash)
        result = ""
        @wrapper_id_list.each do |id|
          wrapper = @wrapper_hash[id]
          value = hash[prefix_key(id)]
          result += "~~~ #{id}=[#{value.class}, default: #{wrapper.default}]= #{value}\n"
        end
        return result
      end

      def construct_hash(converter_id, param)
        hash = {}
        @wrapper_id_list.each do |id|
          wrapper = @wrapper_hash[id]
          hash[prefix_key(id)] = wrapper.convert(converter_id, param)
        end
        return hash
      end

    end

  end
end
