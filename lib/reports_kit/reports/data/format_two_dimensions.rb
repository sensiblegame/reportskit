module ReportsKit
  module Reports
    module Data
      class FormatTwoDimensions
        attr_accessor :series, :dimension, :second_dimension, :dimension_keys_values, :order, :limit

        def initialize(series, dimension_keys_values, order:, limit:)
          self.series = series
          self.dimension = series.dimensions[0]
          self.second_dimension = series.dimensions[1]
          self.dimension_keys_values = dimension_keys_values
          self.order = order
          self.limit = limit
        end

        def perform
          {
            entities: entities,
            datasets: datasets
          }
        end

        private

        def entities
          sorted_primary_keys.map do |primary_key|
            Utils.dimension_key_to_entity(primary_key, dimension, dimension_ids_dimension_instances)
          end
        end

        def datasets
          secondary_keys_values = sorted_secondary_keys.map do |secondary_key|
            raw_values = sorted_primary_keys.map do |primary_key|
              primary_keys_secondary_keys_values[primary_key][secondary_key]
            end
            values = raw_values.map do |raw_value|
              Utils.raw_value_to_value(raw_value, series.value_format_method)
            end
            [secondary_key, values]
          end
          secondary_keys_values.map do |secondary_key, values|
            next if secondary_key.blank?
            {
              entity: Utils.dimension_key_to_entity(secondary_key, second_dimension, second_dimension_ids_dimension_instances),
              values: values
            }
          end.compact
        end

        def sorted_primary_keys_secondary_keys_values
          @sorted_primary_keys_secondary_keys_values ||= begin
            if order.relation == 'dimension1' && order.field == 'label'
              primary_keys_secondary_keys_values
              sorted_primary_keys_secondary_keys_values = primary_keys_secondary_keys_values.sort_by do |primary_key, _|
                primary_dimension_keys_sorted_by_label.index(primary_key)
              end
            elsif order.relation == 'dimension1' && order.field.nil?
              sorted_primary_keys_secondary_keys_values = primary_keys_secondary_keys_values.sort_by do |primary_key, _|
                primary_key
              end
            elsif order.relation == 'count'
              primary_keys_sums = Hash.new(0)
              primary_keys_secondary_keys_values.each do |primary_key, secondary_keys_values|
                primary_keys_sums[primary_key] += secondary_keys_values.values.sum
              end
              sorted_primary_keys = primary_keys_sums.sort_by(&:last).map(&:first)
              sorted_primary_keys_secondary_keys_values = primary_keys_secondary_keys_values.sort_by do |primary_key, _|
                sorted_primary_keys.index(primary_key)
              end
            else
              dimension_keys_values
            end
            sorted_primary_keys_secondary_keys_values = sorted_primary_keys_secondary_keys_values.reverse if order.direction == 'desc'
            Hash[sorted_primary_keys_secondary_keys_values]
          end
        end

        def primary_keys_secondary_keys_values
          @primary_keys_secondary_keys_values ||= begin
            primary_keys_secondary_keys_values = {}
            dimension_keys_values.each do |(primary_key, secondary_key), value|
              primary_key = primary_key.to_date if primary_key.is_a?(Time)
              secondary_key = secondary_key.to_date if secondary_key.is_a?(Time)
              primary_keys_secondary_keys_values[primary_key] ||= {}
              primary_keys_secondary_keys_values[primary_key][secondary_key] = value
            end
            primary_keys_secondary_keys_values
          end
        end

        def dimension_ids_dimension_instances
          @dimension_ids_dimension_instances ||= begin
            Utils.dimension_to_dimension_ids_dimension_instances(dimension, primary_keys)
          end
        end

        def second_dimension_ids_dimension_instances
          @second_dimension_ids_dimension_instances ||= begin
            Utils.dimension_to_dimension_ids_dimension_instances(second_dimension, secondary_keys)
          end
        end

        def sorted_primary_keys
          @sorted_primary_keys ||= begin
            keys = sorted_primary_keys_secondary_keys_values.keys
            limit = dimension.dimension_instances_limit
            keys = keys.first(limit) if limit
            keys
          end
        end

        def sorted_secondary_keys
          @sorted_secondary_keys ||= begin
            keys = sorted_primary_keys_secondary_keys_values.values.first.keys
            limit = second_dimension.dimension_instances_limit
            keys = keys.first(limit) if limit
            keys
          end
        end

        def primary_summaries
          primary_keys.map do |key|
            label = Utils.dimension_key_to_label(key, dimension, dimension_ids_dimension_instances)
            next if label.blank?
            [key, label]
          end.compact
        end

        def primary_dimension_keys_sorted_by_label
          @primary_dimension_keys_sorted_by_label ||= primary_summaries.sort_by { |key, label| label.is_a?(String) ? label.downcase : label }.map(&:first)
        end

        def primary_keys
          @primary_keys ||= dimension_keys_values.keys.map(&:first).uniq
        end

        def secondary_keys
          @secondary_keys ||= dimension_keys_values.keys.map(&:last).uniq
        end
      end
    end
  end
end
