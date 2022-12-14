require 'rails_helper'
require 'json'

RSpec.describe Textract::Data::SqsMessage do
  #let(:fixture_file) { File.join(Rails.root, 'spec', 'fixtures', 'files', 'sample_sqs_message.json') }
  #let(:fixture_data) { JSON.parse(File.read(fixture_file)) }

  describe 'initialization' do
    it 'returns an SqsMessage object' do
      object = Textract::Data::SqsMessage.new
      assert (object.is_a? Textract::Data::SqsMessage)
    end
  end

  #describe 'processing API Data' do
    #describe 'from_hash' do
      #it 'returns an SqsMessage with properties set' do      
        #object = Textract::Data::SqsMessage.from_hash(fixture_data)
        #expect(object).to be_a(Textract::Data::SqsMessage) 
        #assert(object.present?)
      #end
    #end
  #end

end
