require 'yaml'
require 'rubygems'
require 'neo4j'

module Napkin
  module NodeUtil
    #
    #
    class NodeNav
      def initialize(node = Neo4j.ref_node)
        @node = node
      end

      #  def node
      #    return @node
      #  end

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
        if (!go_sub(id)) then
          Neo4j::Transaction.run do
            sub = @node.outgoing(:sub).find{|sub| sub[:id] == id}
            if (sub.nil?) then
              sub = Neo4j::Node.new :id => id
              @node.outgoing(:sub) << sub
              return true;
            end
            @node = sub
          end
        end
        return false;
      end

      def go_sub_path(path)
        path_segments = path.split('/')
        sub_exists = true

        path_segments.each do |segment|
          if (!go_sub(segment))
            sub_exists = false
            break;
          end
        end

        return sub_exists
      end

      def go_sub_path!(path)

      end

      def go_sup()
        sup = @node.incoming(:sub).first
        if (sup.nil?) then
          return false
        else
          @node = sup
          return true
        end
      end

      def get_path
        path_array = [@node[:id]]
        while (go_sup())
          path_array.push(@node[:id])
        end
        return path_array
      end

      def handle(path, method, request, segments, segment, i)

      end

    end

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

    module Props
      FEED_PROPS = PropertyMapper.new(['name','url','refresh_enabled','refresh_in_minutes'])

      FILE_META_PROPS = PropertyMapper.new(['etag', 'last-modified', 'date', 'expires'])
      CHANNEL_PROPS = PropertyMapper.new(['title', 'link', 'description', 'pubDate', 'lastBuildDate'])
      ITEM_PROPS = PropertyMapper.new(['title','link', 'description','guid','pubDate'])
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
  end
end
