require 'csv'
require 'spreadsheet'

module ReportsKit
  class ReportsController < ReportsKit::BaseController
    VALID_PARAMS_PROPERTIES_KEYS = [:ui_filters]

    def index
      respond_to do |format|
        format.json do
          render json: { data: report_data }
        end
        format.csv do
          properties[:format] = 'csv'
          csv = CSV.generate do |csv|
            report_data[:table_data].each do |row|
              csv << row
            end
          end
          send_data csv, filename: "#{report_filename}.csv"
        end
        format.xls do
          properties[:format] = 'csv'
          send_data xls_string, filename: "#{report_filename}.xls", type:  'application/vnd.ms-excel'
        end
      end
    end

    def report_params
      params[:report_params]
    end

    def context_params
      params[:context_params]
    end

    def report_key
      raise ArgumentError.new('Blank report_params') if report_params.blank?
      report_params[:key]
    end

    private

    def report_filename
      report_filename_method = ReportsKit.configuration.report_filename_method
      return 'Report' unless report_filename_method
      instance_eval(&report_filename_method)
    end

    def report_data
      Reports::Data::Generate.new(properties, context_record: context_record).perform
    end

    def properties
      @properties ||= begin
        properties_method = ReportsKit.configuration.properties_method
        properties = instance_eval(&properties_method)
        properties.merge(params_properties).deep_symbolize_keys
      end
    end

    def params_properties
      @params_properties ||= ActiveSupport::JSON.decode(params[:properties]).with_indifferent_access.slice(*VALID_PARAMS_PROPERTIES_KEYS)
    end

    def xls_string
      spreadsheet = Spreadsheet::Workbook.new
      sheet = spreadsheet.create_worksheet
      report_data[:table_data].each_with_index do |row, index|
        sheet.update_row(index, *row)
      end
      io = StringIO.new
      spreadsheet.write(io)
      io.string
    end
  end
end
