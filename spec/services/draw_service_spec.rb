require 'rails_helper'

RSpec.describe DrawService do
  include_context 'draw_service'

  let(:valid_draw_attributes) {
    {
      amount: 1234.56,
      notes: 'Draw notes for test here'
    }
  }
  let(:invalid_draw_attributes) {
    {
      amount: -1,
      notes: 'Draw notes for test here'
    }
  }

  describe 'initialization' do
    it 'creates a service object' do
      service = DrawService.new(user: developer_user, project: project)
    end
    it 'initializes a new draw if none is provided' do
      service = DrawService.new(user: developer_user, project: project)
      expect(service.draw).to be_a(Draw)
      assert(service.draw.new_record?)
      expect(service.draw.project).to eq(project)
      expect(service.draw.user).to eq(developer_user)
      expect(service.draw.organization).to eq(developer_user.organization)
    end
  end # initialize

  describe 'creating a draw' do
    before(:each) { Draw.destroy_all }
    describe 'as a project developer' do
      it 'creates and returns a new draw' do
        service = DrawService.new(user: developer_user, project: project)
        draw = nil
        expect {
          draw = service.create(valid_draw_attributes)
        }.to change{Draw.count}
        refute(service.errors?)
        expect(draw.project).to eq(project)
        expect(draw.user).to eq(developer_user)
        expect(draw.organization).to eq(developer_user.organization)
        expect(draw.amount).to eq(valid_draw_attributes[:amount])
        expect(draw.notes).to eq(valid_draw_attributes[:notes])
      end
    end
    describe 'as a non-authorized user' do
      it 'does not create a draw' do
        investor_user.organization = nil
        investor_user.save!
        service = DrawService.new(user: investor_user, project: project)
        expect {
          draw = service.create(valid_draw_attributes) rescue nil
        }.to_not change{Draw.count}
        expect {
          draw = service.create(valid_draw_attributes)
        }.to raise_error(DrawService::PolicyError)
      end
    end
  end # create

  describe 'updating a draw' do
    describe 'as a developer' do
      let(:user) {sample_project.developers.first}
      let(:draw) { sample_project.draws.first }
      let(:project) { sample_project }
      let(:valid_attrs) { {amount: 444.1, notes: 'New notes'} }

      #before(:each) { sample_project; draw }

      describe 'with valid attributes' do
        it 'updates the draw' do
          service = DrawService.new(user:, project:, draw:)
          service.update(valid_attrs)
          refute(service.errors?)
          draw.reload
          expect(draw.amount).to eq(valid_attrs[:amount])
          expect(draw.notes).to eq(valid_attrs[:notes])
        end
      end
    end
  end # update

  describe 'withdrawing a draw' do
    describe 'as the project developer' do
      it 'transitions the draw to "withdrawn"' do
        service = DrawService.new(user:, project:, draw:)
        assert(draw.pending?)
        service.withdraw
        draw.reload
        assert(draw.withdrawn?)
      end
    end
  end # withdraw
  
end
