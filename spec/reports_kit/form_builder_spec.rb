require 'spec_helper'

describe ReportsKit::FormBuilder do
  subject { described_class.new(properties) }

  context 'with a datetime dimension' do
    let(:properties) do
      {
        measure: 'issue',
        filters: [
          {
            key: 'opened_at',
            criteria: {
              operator: 'between',
              value: '-1w - now'
            }
          }
        ]
      }
    end

    it 'transforms the filter criteria' do
      expect(subject.date_range('opened_at')).to include("#{format_configuration_time(1.week.ago)} - #{format_configuration_time(Time.zone.now)}")
    end
  end
end
