module ReportsKit
  module Reports
    module FilterTypes
      class String < Base
        DEFAULT_CRITERIA = {
          operator: 'contains'
        }

        def apply_conditions(records)
          case criteria[:operator]
          when 'equals'
            records.where("#{column} = ?", value)
          when 'contains'
            records.where("#{column} ILIKE ?", "%#{value}%")
          when 'starts_with'
            records.where("#{column} ILIKE ?", "#{value}%")
          when 'ends_with'
            records.where("#{column} ILIKE ?", "%#{value}")
          when 'does_not_equal'
            records.where("#{column} != ?", value)
          when 'does_not_contain'
            records.where("#{column} NOT ILIKE ?", "%#{value}%")
          when 'does_not_start_with'
            records.where("#{column} NOT ILIKE ?", "#{value}%")
          when 'does_not_end_with'
            records.where("#{column} NOT ILIKE ?", "%#{value}")
          else
            raise ArgumentError.new("Unsupported operator: '#{criteria[:operator]}'")
          end
        end

        def valid?
          value.present?
        end
      end
    end
  end
end
