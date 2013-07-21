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

require 'kramdown'

module Napkin
  module KramdownUtil
    DRAW_CHARTS_JAVASCRIPT = '
<script type="text/javascript" src="https://www.google.com/jsapi"></script>
<script type="text/javascript">
  google.load("visualization", "1.0", {packages:["corechart"]});
  google.setOnLoadCallback(drawCharts);

  function getOptions(id) {
    return {
      "title":"TITLE_TEXT",
      "interpolateNulls":"true",
      "legend":{"position":"bottom"},
      "pointSize":3,
      "width":800, "height":200
    };
  }
  function getRows(id) {
GET_ROWS_BODY_TEXT
  }
  function drawChart(id) {
    var data = new google.visualization.DataTable();
ADD_COLUMNS_BODY_TEXT

    var rows = getRows(id);
    data.addRows(rows);

    var options = getOptions(id);

    var chart = new google.visualization.LineChart(document.getElementById(id));
    chart.draw(data, options);
  }
  function drawCharts() {
    drawChart("chart_div");
  }
</script>
'
    def KramdownUtil.render_line_chart(title, value_labels, time_series)
      html_text = DEFAULT_NODE_GET_HTML.sub(/TITLE_TEXT/, title)

      script_text = DRAW_CHARTS_JAVASCRIPT.sub(/TITLE_TEXT/, title)
      get_rows_body_text = "  return [\n"
      time_series.each do |row|
        get_rows_body_text << "    [#{row[0]}"
        value_labels.each_with_index do |label, index|
          value = row[index+1]
          if (value.nil?) then
            get_rows_body_text << ", null"
          else
            get_rows_body_text << ", #{value}"
          end
        end
        get_rows_body_text << "],\n"
      end
      get_rows_body_text << "  ];\n"
      script_text.sub!(/GET_ROWS_BODY_TEXT/, get_rows_body_text)

      add_columns_body_text = "  data.addColumn('datetime', 'Date');\n"
      value_labels.each do |label|
        add_columns_body_text << "  data.addColumn('number', '#{label}');\n"
      end
      script_text.sub!(/ADD_COLUMNS_BODY_TEXT/, add_columns_body_text)

      html_text.sub!(/SCRIPT_TEXT/, script_text)

      kramdown_body_text ="
# #{title}

<div id='chart_div'></div>
"
      kramdown_doc = Kramdown::Document.new(kramdown_body_text)
      html_body_text = kramdown_doc.to_html
      html_text.sub!(/BODY_TEXT/, html_body_text)
      return html_text
    end

    DEFAULT_NODE_GET_HTML = '
<html>
  <head>
    <title>TITLE_TEXT</title>
SCRIPT_TEXT
  </head>
  <body>
BODY_TEXT
  </body>
</html>
'

    def KramdownUtil.default_node_get_html(kramdown_body_text, title)
      html_text = DEFAULT_NODE_GET_HTML.sub(/TITLE_TEXT/, title)
      html_text.sub!(/SCRIPT_TEXT/, "")

      kramdown_doc = Kramdown::Document.new(kramdown_body_text)
      html_body_text = kramdown_doc.to_html
      html_text.sub!(/BODY_TEXT/, html_body_text)
      return html_text
    end

  end
end
