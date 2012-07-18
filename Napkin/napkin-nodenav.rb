require 'rubygems'
require 'neo4j'

module Napkin
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
end
