require 'yaml'
require 'rss/2.0'

#
require 'rubygems'
require 'neo4j'

# require 'open-uri/cached'

#
require 'napkin-config'
require 'napkin-node-util'
require 'napkin-handlers'
require 'napkin-extensions'

module Napkin
  module Handlers
    class SketchupHandler < HttpMethodHandler
      def handle
        return "" unless at_destination?

        return "?????????????????"
        #        @request.body.rewind
        #        body_text = @request.body.read
        #        body_hash = Napkin::Extensions::Tasks::TrackerTask::FEED_GROUP.yaml_to_hash(body_text, filter=false)
        #
        #        output_text = subclass_handle(body_hash)
        #        if (output_text.nil?)
        #          filtered_text = Napkin::Extensions::Tasks::TrackerTask::FEED_GROUP.hash_to_yaml(body_hash)
        #          "!!! HTTP - #{@method}: '#{get_segment}', #{@nn[NAPKIN_ID]}\n#{body_text}\n!-->\n#{filtered_text}"
        #        else
        #          return output_text
        #        end
      end

      def subclass_handle(body_hash)
        return nil
      end
    end

    #    class FeedPostHandler < FeedHandler
    #      def subclass_handle(body_hash)
    #        id = body_hash[NAPKIN_ID]
    #        return "FeedPostHandler: missing id!" if id.nil?
    #
    #        nn = @nn.dup
    #        nn.go_sub!(id)
    #
    #        Napkin::Extensions::Tasks::TrackerTask::FEED_GROUP.hash_to_node(nn.node, body_hash)
    #
    #        output_hash = Napkin::Extensions::Tasks::TrackerTask::FEED_GROUP.node_to_hash(nn.node)
    #        output_text = Napkin::Extensions::Tasks::TrackerTask::FEED_GROUP.hash_to_yaml(output_hash)
    #        return output_text
    #      end
    #    end

    class SketchupComposePostHandler < HttpMethodHandler
      def handle
        return "" unless at_destination?

        return "???????? SketchupComposePostHandler ?????????"
      end
    end
  end

  module Extensions
    module Tasks
      class SketchupTask < Task
        def init
          super
          puts "!!! SketchupTask.init called !!!"
          init_nodes
        end

        def init_nodes
          nn = Napkin::NodeUtil::NodeNav.new
          nn.go_sub_path!('sketchup/compose')
          nn[NAPKIN_HTTP_POST] = "SketchupComposePostHandler"

          nn.reset
          nn.go_sub_path!('sketchup/models')

          nn.reset
          nn.go_sub_path!('sketchup/fragments')
          # nn[NAPKIN_HTTP_POST] = "SketchupComposePostHandler"
        end

        def cycle
          super
          puts "!!! SketchupTask.cycle called !!!"
          # refresh_feeds
        end
      end
    end
  end
end