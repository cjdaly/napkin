require 'rss/2.0'
require 'yaml'

#
require 'rubygems'
require 'neo4j'

#
require 'napkin-config'
require 'napkin-node-util'

module Napkin
  module ServerUtils

    NF = Napkin::NodeUtil::NodeFinder.new
    #
    # Feed
    #
    def get_feed(id)
      fp = Napkin::NodeUtil::Props::FEED_PROPS
      node = NF.get_sub_path(['feed', id])
      if (node.nil?) then
        halt 404, "Node not found: /feed/#{id}"
      end
      hash = fp.get_hash_for(node)
      return fp.hash_to_yaml(hash)
    end

    def put_feed(id, yaml_text)
      fp = Napkin::NodeUtil::Props::FEED_PROPS
      node = NF.get_sub_path(['feed', id], true)
      yaml_hash = fp.yaml_to_hash(yaml_text)
      fp.adorn_node(node, yaml_hash)
      hash = fp.get_hash_for(node)
      return fp.hash_to_yaml(hash)
    end

    #
    # Sketchup
    #
    def get_sketchup_channel_rss(channel_id, group_id="sketchup", server_url=Napkin::Config::ROOT_URL)
      rss = RSS::Rss.new("2.0")
      ch = RSS::Rss::Channel.new
      rss.channel = ch

      ch.title="#{channel_id}"
      ch.description = "Feed #{channel_id} description"
      ch.link = "#{server_url}/#{group_id}/#{channel_id}"

      3.times do |n|
        item = RSS::Rss::Channel::Item.new
        item.title = "item#{n}"
        item.link = "#{server_url}/#{group_id}/#{channel_id}/item-#{n}.rb"
        ch.items << item
      end

      return rss.to_s
    end

    def get_sketchup_item_rb(channel_id, item_id)
      "puts \"Here is item-#{item_id} from channel #{channel_id}!\""
    end

    def handle_request (path, method, request)
      content_type 'text/plain'
      nn = Napkin::NodeUtil::NodeNav.new
      segments = path.split('/')

      response_text = "[#{segments.length}] "

      current_segment_index = 0
      segments.each_with_index do |segment, i|
        if (nn.go_sub(segment)) then
          #        case method
          #        when :get
          #        when :post
          #        when :put
          #        else
          #        end

          # nn.handle(path, method, request, segments, segment, i)
          response_text += "#{i}:#{segment} / "
        else
          break
        end
        current_segment_index += 1
      end

      if (current_segment_index != segments.length) then
        missing_segment = segments[current_segment_index]
        halt 404, "Node not found: #{missing_segment} in #{path}"
      else
        return response_text
      end
    end

    def get_node(path)
      content_type 'text/plain'

      nn = Napkin::NodeUtil::NodeNav.new
      if (nn.go_sub_path(path))
        "found: #{nn.get_path()}"
      else
        "not found: #{path} (found: #{nn.get_path()})"
      end
    end

    def post_node(path, content)
      content_type 'text/plain'

      nn = Napkin::NodeUtil::NodeNav.new

      "POST not implemented"
    end

    def put_node(path, content)
      content_type 'text/plain'
      "PUT not implemented"
    end

    def echo_params(path)
      if (path == nil)
        "path: NIL"
      elsif (path =="")
        "path: ''"
      else
        path_segments = path.split('/')
        "path: #{path} -> #{path_segments.join(' : ')}"
      end
    end

    class Authenticator
      NF = Napkin::NodeUtil::NodeFinder.new
      def check(username, password)
        node = NF.get_sub('user')
        if (node.nil?) then
          return username == 'fred' && password == 'fred'
        end
        node = NF.get_sub(username, node)
        if (node.nil?) then
          return false
        else
          return password == 'fred'
        end
      end
    end

    class Tracker2
      def init_nodes
        nn = NodeNav2.new
        nn.go_sub_path!('tracker/feed')
        nn.reset

        nn.go_sub_path!('tracker/cycle')
        nn.get_or_init('cycle_count',0)
        nn.get_or_init('pre_cycle_delay_seconds',5)
        nn.get_or_init('post_cycle_delay_seconds',1)
      end

      def init_git
        @cache_dir = OpenURI::Cache.cache_path
        git_command("config --file #{@cache_dir}/.git/config user.name Fred")
        git_command("config --file #{@cache_dir}/.git/config user.email fred@example.com")
      end
      #
      #      def initialize
      #        init_nodes
      #        init_git
      #      end

      def cycle
        foo = Neo4j.ref_node['foo']
        Neo4j::Transaction.run do
          Neo4j.ref_node['foo'] = "hi ... #{foo}"
        end
        puts "!!!!! #{foo} -> #{Neo4j.ref_node['foo']}"

        @enabled = true
        @thread = Thread.new do
          begin
            # ??? this seems to be necessary ???
            sleep 0.1

            init_nodes
            init_git

            puts "Tracker thread started..."
            # @n = NodeNav2.new
            # helper = RssReader.new
            while (next_cycle2)
              puts "Tracker thread - cycle: #{@cycle_count}"

              # sleep @pre_cycle_delay_seconds
              sleep 3
              if (@enabled)
                # helper.refresh_feeds(@delay)
                puts "Tracker thread refreshed..."
              else
                puts "Tracker thread disabled..."
              end
              # do_git_stuff()

              # sleep @post_cycle_delay_seconds
            end
            puts "Tracker thread stopped..."
          rescue StandardError => err
            puts "Error in Tracker thread: #{err}\n#{err.backtrace}"
          end
        end
      end

      def next_cycle
        foo = Neo4j.ref_node['foo']

        Neo4j::Transaction.run do
          Neo4j.ref_node['foo'] = "next ... #{foo}"
        end

        puts "!!! #{foo} -> #{Neo4j.ref_node['foo']}"

        return true
      end

      def next_cycle2
        @n = NodeNav2.new
        result = @n.go_sub_path('tracker/cycle')
        puts "!!! #{result} / #{@n.get_path} / #{@n['cycle_count']}"

        @cycle_count = @n['cycle_count']
        @cycle_count += 1

        #      Neo4j::Transaction.run do
        #        # @n.node['cycle_count'] = @cycle_count
        #      end

        @n.set_property('cycle_count', @cycle_count)

        #
        puts "!!! #{@n.get_path} / #{@n['cycle_count']}"

        #      Neo4j::Transaction.run do
        #        nn = Napkin::NodeUtil::NodeNav.new
        #        nn.go_sub_path('tracker/cycle')
        #        puts "!!! #{nn.get_path}"
        ##        @cycle_count = nn['cycle_count']
        ##        @cycle_count += 1
        ##        nn['cycle_count'] = @cycle_count
        ##        @pre_cycle_delay_seconds = nn['pre_cycle_delay_seconds']
        ##        @post_cycle_delay_seconds = nn['post_cycle_delay_seconds']
        #      end

        return true
      end

      def do_git_stuff()
        git_command("init")
        git_command("status -s")
        git_command("add .")
        git_command("commit -m \"...\"")
        git_command("status -s")
        git_command("tag -a loop-#{@cycle_count} -m \"...\"")
      end

      def git_command(command, cache_dir=@cache_dir, git_dir=@cache_dir + "/.git")
        command_text = "git --git-dir=#{git_dir} --work-tree=#{cache_dir} #{command}"
        result_text = `#{command_text}`
        result_status = $?
        puts "[exec] git ... #{command}\n  -> #{result_status}\n#{result_text}"
      end
    end

    class NodeNav2
      attr_accessor :node
      def initialize(node = Neo4j.ref_node)
        @node = node
      end

      def reset(node = Neo4j.ref_node)
        @node = node
      end

      def [](key)
        return @node[key]
      end

      def []=(key, value)
        Neo4j::Transaction.run do
          @node[key] = value
        end
      end

      def set_property(key, value)
        Neo4j::Transaction.run do
          @node[key] = value
        end
      end

      def init_property(key, default)
        property_initialized = true
        Neo4j::Transaction.run do
          if (@node[key].nil?) then
            @node[key] = default
          else
            property_initialized = false
          end
        end
        return property_initialized
      end

      def get_or_init(key, default)
        value = @node[key]
        if (value.nil?) then
          Neo4j::Transaction.run do
            value = @node[key]
            if (value.nil?) then
              @node[key] = default
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

      def go_sub_path!(path)
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
        #        nn = dup
        #        path = "#{nn.get_segment}"
        #        while (nn.go_sup())
        #          path = "#{nn.get_segment}/" + path
        #        end
        #        return path
        return "???"
      end

      def get_segment
        segment = @node[:id]
        segment.nil? ? 'nil' : segment
      end

      def handle(path, method, request, segments, segment, i)

      end

    end
  end
end

