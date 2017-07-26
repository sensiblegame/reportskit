module ReportsKit
  module Reports
    class AbstractSeries
      def value_format_method
        ReportsKit.configuration.custom_method(properties[:value_format_method])
      end
    end
  end
end
