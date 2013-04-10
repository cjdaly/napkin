require 'yaml'
require 'rubygems'
require 'neo4j'

#
require 'napkin-config'
require 'napkin-extensions'

module Napkin
  module NodeUtil
    NAPKIN_ID_INDEX = 'napkin#_index_id'
    NAPKIN_ID_INDEX_FILE = 'napkin_id'
    class NapkinIdIndex
      extend Neo4j::Core::Index::ClassMethods
      include Neo4j::Core::Index

      self.node_indexer do
        index_names :exact => NAPKIN_ID_INDEX_FILE
        trigger_on NAPKIN_ID_INDEX => true
      end

      index NAPKIN_ID
    end

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

      def increment(key, initial = 0)
        Neo4j::Transaction.run do
          count = get_or_init(key, initial)
          count += 1
          @node[prefix_key(key)] = count
        end
      end

      def go_sub(id)
        begin
          sub = find_sub(id)
          if (sub.nil?) then
            return false
          else
            @node = sub
            return true
          end
        rescue StandardError => err
          puts "Error in go_sub: #{err}\n#{err.backtrace}"
          return false;
        end
      end

      def go_sub!(id)
        created_node = false
        if (!go_sub(id)) then
          Neo4j::Transaction.run do
            sub = find_sub(id)
            if (sub.nil?) then
              sub = Neo4j::Node.new(NAPKIN_ID => id, NAPKIN_ID_INDEX => true)
              @node.outgoing(NAPKIN_SUB) << sub
              created_node = true
            end
            @node = sub
          end
        end
        return created_node;
      end

      def find_sub(id)
        sub = nil
        
        Neo4j::Transaction.run do
          # TODO: got exception here after several days of continuous run:
          ## org.apache.lucene.store.AlreadyClosedException: this IndexReader is closed
          nodes = NapkinIdIndex.find(NAPKIN_ID => id)

          nodes.each do |n|
            if (NodeNav.get_sup(n) == @node)
              sub = n if sub.nil?
            end
          end
        end
   
        return sub
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
          # TODO: bad hash
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

      def NodeNav.get_sup(node)
        sup = node.incoming(NAPKIN_SUB).first()
        return sup
      end

      def go_sup
        sup = NodeNav.get_sup(@node)
        if (sup.nil?) then
          return false
        else
          @node = sup
          return true
        end
      end

      def NodeNav.get_path(node)
        path = NodeNav.get_segment(node)
        n = NodeNav.get_sup(node)
        while (!n.nil?)
          path = NodeNav.get_segment(n) + "/" + path
          n = NodeNav.get_sup(n)
        end
        return path
      end

      def get_path
        return NodeNav.get_path(@node)
      end

      def NodeNav.get_segment(node)
        segment = node[NAPKIN_ID]
        return segment.nil? ? '~' : segment
      end

      def get_segment
        return NodeNav.get_segment(@node)
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
            result = "Error in convert: #{err}\n#{err.backtrace}"
            puts result
          end
        end
        return result
      end

    end

    class PropertyGroup
      # TODO: bad hash
      def initialize(id, separator='#')
        @id = id
        @separator = separator
        @wrapper_id_list = []
        @wrapper_hash = {}
      end

      def prefix_key(key)
        "#{@id}#{@separator}#{key}"
      end

      def get(node, key)
        return node[prefix_key(key)]
      end

      def set(node, key, value)
        Neo4j::Transaction.run do
          node[prefix_key(key)] = value
        end
      end

      def get_or_init(node, key, default)
        value = node[prefix_key(key)]
        if (value.nil?) then
          Neo4j::Transaction.run do
            value = node[prefix_key(key)]
            if (value.nil?) then
              node[prefix_key(key)] = default
              value = default
            end
          end
        end
        return value
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
