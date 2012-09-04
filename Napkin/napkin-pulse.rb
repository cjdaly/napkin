require 'rubygems'
require 'neo4j'
require 'napkin-node-util'
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
              puts "Pulse thread - cycle: #{@cycle_count}"
              sleep @pre_cycle_delay_seconds
              if (@enabled)
                process_tasks
                puts "Pulse thread refreshed..."
              else
                puts "Pulse thread disabled..."
              end

              sleep @post_cycle_delay_seconds
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

        @cycle_count = nn['cycle_count']
        @cycle_count += 1
        nn['cycle_count']= @cycle_count

        @pre_cycle_delay_seconds = nn.get_or_init('pre_cycle_delay_seconds', 9)
        @mid_cycle_delay_seconds = nn.get_or_init('mid_cycle_delay_seconds', 5)
        @post_cycle_delay_seconds = nn.get_or_init('post_cycle_delay_seconds', 1)

        nn.go_sub!("#{@cycle_count}")

        nn['cycle_start_time'] = "#{cycle_start_time}"
        nn['cycle_start_time_i'] = cycle_start_time.to_i

        #
        puts ">>> CYCLE: #{nn.get_path} / #{nn['cycle_count']}"

        return true
      end

      def process_tasks
        @tasks_list.each do |task_id|
          puts "Task #{task_id} processing..."
          task_class = @tasks_hash[task_id]
          task = task_class.new
          process_task(task)
          sleep @mid_cycle_delay_seconds
        end
      end

      def process_task(task)
        task.cycle
      end

      def init_tasks
        @tasks_hash = {}
        @tasks_list = []

        nn = Napkin::NodeUtil::NodeNav.new
        nn.go_sub_path!('napkin/tasks', true)

        nn.node.outgoing(:sub).each do |sub|
          init_task(sub)
        end
      end

      def init_task(node)
        task_id = node[:id]
        task_class = get_task_class(node)

        # TODO: establish consistent/declared task order
        @tasks_list.push(task_id)
        @tasks_hash[task_id] = task_class

        puts "Task #{task_id} initialized..."
      end

      def get_task_class(node)
        nn = Napkin::NodeUtil::NodeNav.new(node)
        nn.property_key_prefix="napkin/tasks"

        task_class_name = nn["task_class_name"]
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
end