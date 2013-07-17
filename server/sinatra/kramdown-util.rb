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
GET_OPTIONS_BODY
  };
  function getRows(id) {
GET_ROWS_BODY
  };
  function drawChart(id) {
    var data = new google.visualization.DataTable();
    data.addColumn("datetime", "Date");

    var rows = getRows(id);
    data.addRows(rows);

    var options = getOptions(id);

    var chart = new google.visualization.LineChart(document.getElementById(id));
    chart.draw(data, options);
  };
  function drawCharts() {
    drawChart("chart_div");
  };
</script>
'

    DEFAULT_NODE_GET_HTML = '
<html>
  <head>
    <title>TITLE_TEXT</title>
  </head>
  <body>
BODY_TEXT
  </body>
</html>
'
    def KramdownUtil.default_node_get_html(kramdown_body_text, title)
      kramdown_doc = Kramdown::Document.new(kramdown_body_text)
      html_body_text = kramdown_doc.to_html
      html_text = DEFAULT_NODE_GET_HTML.sub(/TITLE_TEXT/, title)
      html_text = html_text.sub!(/BODY_TEXT/, html_body_text)
      return html_text
    end

  end
end
