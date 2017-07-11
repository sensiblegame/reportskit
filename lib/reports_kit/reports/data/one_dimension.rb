module ReportsKit
  module Reports
    module Data
      class OneDimension
        attr_accessor :measure

        def initialize(measure)
          self.measure = measure
        end

        def perform
          dimension_keys_values
        end

        private

        def dimension_keys
          dimension_keys_values.keys
        end

        def dimension_keys_values
          dimension_with_measure = DimensionWithMeasure.new(dimension: measure.dimensions.first, measure: measure)
          relation = measure.filtered_relation
          relation = relation.group(dimension_with_measure.group_expression)
          relation = relation.joins(dimension_with_measure.joins) if dimension_with_measure.joins
          relation = relation.limit(dimension_with_measure.dimension_instances_limit) if dimension_with_measure.dimension_instances_limit
          # If the dimension's order_column is 'name', we can't sort it in SQL and will instead need to sort it in memory, where we have
          # access to the #to_s method of the dimension instances.
          if dimension_with_measure.order_column == 'count'
            relation = relation.order("1 #{dimension_with_measure.order_direction}")
          elsif dimension_with_measure.order_column == 'time'
            relation = relation.order("2 #{dimension_with_measure.order_direction}")
          end
          dimension_keys_values = relation.distinct.public_send(*measure.aggregate_function)
          dimension_keys_values = Utils.populate_sparse_hash(dimension_keys_values, dimension: dimension_with_measure)
          dimension_keys_values.delete(nil)
          dimension_keys_values.delete('')
          dimension_keys_values
        end

        def values
          dimension_keys_values.values.map { |value| value.round(Generate::ROUND_PRECISION) }
        end

        def labels
          dimension_keys.map do |key|
            Utils.dimension_key_to_label(key, primary_dimension_with_measure, dimension_ids_dimension_instances)
          end
        end

        def dimension_ids_dimension_instances
          @dimension_ids_dimension_instances ||= begin
            dimension_ids = dimension_keys_values.keys
            Utils.dimension_to_dimension_ids_dimension_instances(primary_dimension_with_measure, dimension_ids)
          end
        end

        def primary_dimension_with_measure
          @primary_dimension_with_measure ||= DimensionWithMeasure.new(dimension: measure.dimensions.first, measure: measure)
        end
      end
    end
  end
end
