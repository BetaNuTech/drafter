require 'rails_helper'
require 'json'

RSpec.describe Textract::Data::AnalysisJobData do

  describe 'initialization' do
    it 'returns an analysis_job_data object' do
      object = Textract::Data::AnalysisJobData.new
      assert (object.is_a? Textract::Data::AnalysisJobData)
    end
  end

  describe 'processing API Data' do
    it 'returns an analysis_job_data with properties set' do      
      filename = File.join(Rails.root, 'spec', 'fixtures', 'files', 'sample_textract_ analyzeExpenseResponse.json')
      data = JSON.parse(File.read(filename))
      object = Textract::Data::AnalysisJobData.from_api(response: data, job_id: 1, expected_total: 9069.00)
      expect(object).to be_a(Textract::Data::AnalysisJobData) 
      expect(object.total).to eq(9069.00)
      expect(object.page_number).to eq(3)
      expect(object.is_total_present).to eq(true)
      expect(object.confidence).to be >= 95
      expect(object.job_id).to eq(1)
      expect(object.bounding_box).to_not eq({})
    end
  end

end
