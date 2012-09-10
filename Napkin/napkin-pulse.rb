require 'rubygems'
require 'neo4j'
require 'napkin-node-util'
require 'napkin-handlers'
require 'napkin-extensions'

module Napkin
  module Core
    class Pulse
      def cycle
        @enabled = true
        @thread = Thread.new do
          begin
            puts "Pulse thread started..."

            # let Neo4J warm up to this thread...
            sleep 3

            init_tasks

            puts "Pulse thread initialized..."
            while (next_cycle)
              nn = Napkin::NodeUtil::NodeNav.new
              nn.go_sub_path!('napkin/cycles', true)
              cycle_count = nn['cycle_count']
              puts "Pulse thread - cycle: #{cycle_count}"

              pre_cycle_delay_seconds = nn.get_or_init('pre_cycle_delay_seconds', 5)
              sleep pre_cycle_delay_seconds
              if (@enabled)
                process_tasks
                puts "Pulse thread refreshed..."
              else
                puts "Pulse thread disabled..."
              end

              post_cycle_delay_seconds = nn.get_or_init('post_cycle_delay_seconds', 1)
              sleep post_cycle_delay_seconds
            end
            puts "Pulse thread stopped..."
          rescue StandardError => err
            puts "Error in Pulse thread: #{err}\n#{err.backtrace}"
          end
        end
      end

      def next_cycle
        cycle_start_time = Time.now

        nn = Napkin::NodeUtil::NodeNav.new
        nn.go_sub_path!('napkin/cycles', true)

        cycle_count = nn['cycle_count']
        cycle_count += 1
        nn['cycle_count']= cycle_count

        nn.go_sub!("#{cycle_count}")

        nn['cycle_start_time'] = "#{cycle_start_time}"
        nn['cycle_start_time_i'] = cycle_start_time.to_i

        #
        puts ">>> CYCLE: #{nn.get_path} / #{nn['cycle_count']}"

        return true
      end

      def process_tasks
        nn = Napkin::NodeUtil::NodeNav.new
        nn.go_sub_path!('napkin/tasks')

        nn.node.outgoing(NAPKIN_SUB).each do |sub|
          task_id = sub[NAPKIN_ID]
          task_name = TASKS_GROUP.get(sub, 'task_name')
          task_enabled = TASKS_GROUP.get(sub, 'task_enabled')
          if (!task_enabled) then
            puts "Task: #{task_name} (id: #{task_id}) skipped. Task not enabled."
          else
            task = construct_task(sub)
            if (task.nil?) then
              puts "Task: #{task_name} (id: #{task_id}) skipped. No handler class."
            else
              puts "Task: #{task_name} (id: #{task_id}) processing..."
              process_task(task)
            end
          end

          mid_cycle_delay_seconds = nn.get_or_init('mid_cycle_delay_seconds', 5)
          sleep mid_cycle_delay_seconds
        end
      end

      def process_task(task)
        begin
          task.cycle
        rescue StandardError => err
          puts "Error in process_task: #{err}\n#{err.backtrace}"
        end
      end

      TASKS_GROUP = Napkin::NodeUtil::PropertyGroup.new('napkin/tasks').
      add_property('task_name').group.
      add_property('task_class').group.
      add_property('task_enabled').group

      def init_tasks
        nn = Napkin::NodeUtil::NodeNav.new
        nn.go_sub_path!('napkin/tasks')
        nn[NAPKIN_HTTP_POST] = "TaskPostHandler"

        nn.set_key_prefix("napkin/tasks")
        post_init_delay_seconds = nn.get_or_init('post_init_delay_seconds', 2)

        nn.node.outgoing(NAPKIN_SUB).each do |sub|
          task_id = sub[NAPKIN_ID]
          task_name = TASKS_GROUP.get(sub, 'task_name')

          task = construct_task(sub)
          if (task.nil?) then
            puts "Task: #{task_name} (id: #{task_id}) initialization skipped. No handler class."
          else
            puts "Task: #{task_name} (id: #{task_id}) initializing..."
            init_task(task)
          end

          sleep post_init_delay_seconds
        end
      end

      def init_task(task)
        begin
          task.init
        rescue StandardError => err
          puts "Error in init_task: #{err}\n#{err.backtrace}"
        end
      end

      def construct_task(node)
        task = nil
        begin
          task_class = get_task_class(node)
          task = task_class.new
        rescue StandardError => err
          puts "Error in construct_task: #{err}\n#{err.backtrace}"
        end
        return task
      end

      def get_task_class(node)
        nn = Napkin::NodeUtil::NodeNav.new(node)
        nn.set_key_prefix("napkin/tasks")

        task_class_name = nn["task_class"]
        if (task_class_name.nil?) then
          return Napkin::Extensions::Tasks::NilTask
        end

        task_class = Napkin::Extensions::Tasks.const_get(task_class_name)
        if (task_class.nil?) then
          return Napkin::Extensions::Tasks::NilTask
        end

        return task_class
      end
    end
  end

  module Extensions
    module Tasks
      class TestTask < Task
        def init
          super
          puts "!!! TestTask.init called !!!"
        end

        def cycle
          super
          puts "!!! TestTask.cycle called !!!"
        end
      end
    end
  end

  module Handlers
    class TaskPostHandler < HttpMethodHandler
      def handle
        return "" unless at_destination?

        @request.body.rewind
        body_text = @request.body.read
        body_hash = Napkin::Core::Pulse::TASKS_GROUP.yaml_to_hash(body_text, filter=false)

        id = body_hash[NAPKIN_ID]
        return "TaskPostHandler: missing id!" if id.nil?

        nn = @nn.dup
        nn.go_sub!(id)

        Napkin::Core::Pulse::TASKS_GROUP.hash_to_node(nn.node, body_hash)

        output_hash = Napkin::Core::Pulse::TASKS_GROUP.node_to_hash(nn.node)
        output_text = Napkin::Core::Pulse::TASKS_GROUP.hash_to_yaml(output_hash)
        return output_text
      end
    end
  end
end
