####
# Copyright (c) 2013 Chris J Daly (github user cjdaly)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   cjdaly - initial API and implementation
####
require 'haml'

module Napkin
  module HamlUtil
    def HamlUtil.render_line_chart(title, value_labels, time_series)
      haml_text =  "%html\n"
      haml_text << "  %head\n"
      haml_text << "    %script{:type => 'text/javascript', :src => 'https://www.google.com/jsapi'}\n"
      haml_text << "    %script{:type => 'text/javascript'}\n"
      haml_text << "      google.load('visualization', '1.0', {'packages':['corechart']});\n"
      haml_text << "      google.setOnLoadCallback(drawChart);\n"
      haml_text << "      function drawChart() {\n"
      haml_text << "      var data = new google.visualization.arrayToDataTable([\n"

      haml_text << "      ['Time'"
      value_labels.each do |label|
        haml_text << ", '#{label}'"
      end
      haml_text << "]\n"

      time_series.each do |row|
        haml_text << "      ,['#{row[0]}'"
        value_labels.each_with_index do |label, index|
          haml_text << ", #{row[index+1]}"
        end
        haml_text << "]\n"
      end

      haml_text << "      ]);\n"
      haml_text << "      var options = {\n"
      haml_text << "      'title':'#{title}',\n"
      haml_text << "      'width':800, 'height':200\n"
      haml_text << "      };\n"
      haml_text << "      var chart = new google.visualization.LineChart(document.getElementById('chart_div'));\n"
      haml_text << "      chart.draw(data, options);\n"
      haml_text << "      }\n"
      haml_text << "  %body\n"
      haml_text << "    %div{:id=>'chart_div'}\n"

      haml_engine = Haml::Engine.new(haml_text)
      haml_out = haml_engine.render
      return haml_out
    end

  end
end