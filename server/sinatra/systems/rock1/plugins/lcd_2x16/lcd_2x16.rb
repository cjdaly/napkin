####
# Copyright (c) 2014 Chris J Daly (github user cjdaly)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   cjdaly - initial API and implementation
####

module Napkin::Plugins
  class Lcd_2x16 < PluginBase
    def init
      # service_node_id = init_service_segment
      register_task('lcd-update', LcdUpdate_Task)
      puts "In Lcd_2x16.init() !!!"
    end

    class LcdUpdate_Task < Napkin::Tasks::TaskBase
      include Napkin::Util::Client
      LCD_UART_DEVICE = "/dev/ttyS3"
      def init
        puts "In Cerb3.SensorData_Task.init() !!!"
        @count = 0
      end

      def fini
        puts "In Cerb3.SensorData_Task.fini() !!!"
      end

      def cycle
        @count += 1
        clear_lcd()
        write_lcd("hello world", "count: #{@count}")
      end

      #
      # lcd util code
      #

      LCD_CMD_PRE = "\xfe"
      LCD_CMD_CLS = "\x01"
      LCD_CMD_NL = "\xc0"

      def write_lcd(line1, line2)
        File.open(LCD_UART_DEVICE, "w") do |file|
          file.write("#{LCD_CMD_PRE}#{LCD_CMD_CLS}")
          file.write(line1)
          file.write("#{LCD_CMD_PRE}#{LCD_CMD_NL}")
          file.write(line2)
        end
      end

      def clear_lcd()
        File.open(LCD_UART_DEVICE, "w") do |file|
          file.write("#{LCD_CMD_PRE}#{LCD_CMD_CLS}")
        end
      end

      def truncate(text, length = 16)
        if (text.length >= length) then
          end_position = length - 1
          text = text[0..end_position]
        else
          text = text.rjust(length)
        end
        return text
      end

    end
  end
end