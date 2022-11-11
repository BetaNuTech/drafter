require './spec/support/project_spec_helper'
RSpec.configure do |c|
  c.include ProjectSpecHelper
end

RSpec.shared_context 'sample_draws' do
  include_context 'sample_projects'

  let(:developer_user) { sample_project.developers.first }

  let(:uploaded_file) {Rack::Test::UploadedFile.new("#{Rails.root}/spec/fixtures/files/sample_document_1.pdf", 'application/pdf')}
  let(:draw) { sample_project.draws.first}
  let(:draw_cost) {
    create(:draw_cost, draw: draw, project_cost: sample_project.project_costs.first, total: 4000.0, state: 'pending')
  }
  let(:draw_cost2) {
    create(:draw_cost, draw: draw, project_cost: sample_project.project_costs.last, total: 4000.0, state: 'pending')
  }
  let(:draw_cost_invoices) {
    draw_cost.invoices.create!(amount: 2000.0, description: 'Test invoice 1', document: uploaded_file, user: developer_user)
    draw_cost.invoices.create!(amount: 2000.0, description: 'Test invoice 1', document: uploaded_file, user: developer_user)
    draw_cost.invoices
  }
  let(:draw_cost2_invoices) {
    draw_cost2.invoices.create!(amount: 2000.0, description: 'Test invoice 1', document: uploaded_file, user: developer_user)
    draw_cost2.invoices.create!(amount: 2000.0, description: 'Test invoice 1', document: uploaded_file, user: developer_user)
    draw_cost2.invoices
  }
  let(:invoices) { draw_cost_invoices }
end
