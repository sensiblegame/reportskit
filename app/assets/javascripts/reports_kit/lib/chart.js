ReportsKit.Chart = (function(options) {
  var self = this;

  self.initialize = function(options) {
    self.options = options;
    self.report = options.report;
    self.el = self.report.el;

    self.canvas = $('<canvas />').appendTo(self.report.visualizationEl);
  };

  self.render = function() {
    var path = self.el.data('path');
    var separator = path.indexOf('?') === -1 ? '?' : '&';
    path += separator + 'properties=' + encodeURIComponent(JSON.stringify(self.report.properties()));
    $.getJSON(path, function(response) {
      var data = response.data;
      var chartData = data.chart_data;
      var options = chartData.options;
      options = self.addAdditionalOptions(options, chartData.standard_options)

      var args = {
        type: data.type,
        data: chartData,
        options: options
      };

      if (self.chart) {
        self.chart.data.datasets = chartData.datasets;
        self.chart.data.labels = chartData.labels;
        self.chart.update();
      } else {
        self.chart = new Chart(self.canvas, args);
      }
    });
  };

  self.addAdditionalOptions = function(options, standardOptions) {
    var additionalOptions = {};
    var maxItems = standardOptions && standardOptions.legend && standardOptions.legend.max_items;
    if (maxItems) {
      additionalOptions = {
        legend: {
          labels: {
            filter: function(item) {
              return item.index < maxItems;
            }
          }
        }
      };
      options = $.extend(true, options, additionalOptions);
    }
    return options;
  };

  self.initialize(options);

  return self;
});
