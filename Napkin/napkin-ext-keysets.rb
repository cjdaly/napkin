require 'yaml'
require 'rss/2.0'

#
require 'rubygems'
require 'neo4j'

#
require 'napkin-config'
require 'napkin-node-util'
require 'napkin-handlers'
require 'napkin-extensions'
require 'napkin-keysets'

module Napkin
  module Handlers
    class KeysetPostHandler < HttpMethodHandler
      def handle
        return "" unless at_destination?

        @request.body.rewind
        body_text = @request.body.read
        body_hash = Napkin::Extensions::Tasks::KeysetsTask::KEYSET_GROUP.yaml_to_hash(body_text, filter=false)

        id = body_hash[NAPKIN_ID]
        return "KeysetPostHandler: missing id!" if id.nil?

        nn = @nn.dup
        nn.go_sub!(id)

        Napkin::Extensions::Tasks::KeysetsTask::KEYSET_GROUP.hash_to_node(nn.node, body_hash)

        output_hash = Napkin::Extensions::Tasks::KeysetsTask::KEYSET_GROUP.node_to_hash(nn.node)
        output_text = Napkin::Extensions::Tasks::KeysetsTask::KEYSET_GROUP.hash_to_yaml(output_hash)
        return output_text
      end
    end
  end

  module Extensions
    module Tasks
      class KeysetsTask < Task
        def init
          super
          puts "!!! KeysetsTask.init called !!!"
          init_nodes
        end

        def init_nodes
          nn = Napkin::NodeUtil::NodeNav.new
          nn.go_sub_path!('keysets')
          nn[NAPKIN_HTTP_POST] = "KeysetPostHandler"
        end

        def cycle
          super
          puts "!!! KeysetsTask.cycle called !!!"
        end

      # TODO: bad slash
        KEYSET_GROUP = Napkin::NodeUtil::PropertyGroup.new('napkin/keysets').
        add_property('keyset_name').group.
        add_property('keyset_description').group.
        add_property('keyset_index_id').group
      end
    end
  end
end
