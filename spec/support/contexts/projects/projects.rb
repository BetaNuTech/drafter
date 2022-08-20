require './spec/support/project_spec_helper'
RSpec.configure do |c|
  c.include ProjectSpecHelper
end

RSpec.shared_context 'projects' do
  include_context 'roles'
  include_context 'project_roles'

  let(:project1) { create(:project) }

  before do
    project1
  end

end
