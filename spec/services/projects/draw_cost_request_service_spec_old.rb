require 'rails_helper'

RSpec.describe Projects::DrawCostRequestService do
  include_context 'draw_cost_request_service'

  describe 'initialization' do
    it 'creates a service object' do
      user = sample_project.developers.first
      service = Projects::DrawCostRequestService.new(user: user, draw_cost: draw_cost)
    end

    describe 'access control' do
      describe 'when the user is not a member of the project' do
        it 'allows administrators' do
          service = Projects::DrawCostRequestService.new(user: admin_user, draw_cost: draw_cost)
        end
        it 'disallows non-administrators' do
          expect {
            service = Projects::DrawCostRequestService.new(user: regular_user, draw_cost: draw_cost)
          }.to raise_error(Projects::DrawCostRequestService::PolicyError)
        end
      end
      describe 'when the user is a member of the project' do
        it 'allows project owner' do
          user = owner_user
          service = Projects::DrawCostRequestService.new(user: user, draw_cost: draw_cost)
        end
        it 'allows project manager' do
          user = manager_user
          service = Projects::DrawCostRequestService.new(user: user, draw_cost: draw_cost)
        end
        it 'allows project developer' do
          user = developer_user
          service = Projects::DrawCostRequestService.new(user: user, draw_cost: draw_cost)
        end
        it 'allows project consultants' do
          user = consultant_user
          service = Projects::DrawCostRequestService.new(user: user, draw_cost: draw_cost)
        end
        it 'allows project finance' do
          user = finance_user
          service = Projects::DrawCostRequestService.new(user: user, draw_cost: draw_cost)
        end
      end # Project Members
    end # Access Control
  end # Initialization

  describe 'creating a draw cost request' do
    let(:valid_attributes) { valid_draw_cost_request_attributes }
    let(:invalid_attributes) { invalid_draw_cost_request_attributes }
    describe 'initializing the service with a draw' do
      it 'should create a draw cost request' do
        user = developer_user
        service = Projects::DrawCostRequestService.new( user: user, draw: draw)
        dcr = nil
        expect {
          dcr = service.create_request(valid_attributes)
        }.to change{DrawCostRequest.count}
        refute service.errors?
      end
    end
    describe "without an existing draw cost request for the draw and user's organization" do
      describe 'as an admin' do
        it 'should create a draw cost request' do
          user = admin_user
          service = Projects::DrawCostRequestService.new(user: user, draw_cost: draw_cost)
          dcr = nil
          expect {
            dcr = service.create_request(valid_attributes)
          }.to change{DrawCostRequest.count}
          refute(service.errors?)
        end
      end
      describe 'as a project owner' do
        it 'should create a draw cost request' do
          user = owner_user
          service = Projects::DrawCostRequestService.new(user: user, draw_cost: draw_cost)
          dcr = nil
          expect {
            dcr = service.create_request(valid_attributes)
          }.to change{DrawCostRequest.count}
          refute(service.errors?)
        end
      end
      describe 'as a project manager' do
        it 'should not create a draw cost request' do
          user = manager_user
          service = Projects::DrawCostRequestService.new(user: user, draw_cost: draw_cost)
          dcr = nil
          expect {
            dcr = service.create_request(valid_attributes)
          }.to raise_error(Projects::DrawCostRequestService::PolicyError)
        end
      end
      describe 'as a consultant' do
        it 'should not create a draw cost request' do
          user = consultant_user
          service = Projects::DrawCostRequestService.new(user: user, draw_cost: draw_cost)
          dcr = nil
          expect {
            dcr = service.create_request(valid_attributes)
          }.to raise_error(Projects::DrawCostRequestService::PolicyError)
        end
      end
      describe 'as a finance user' do
        it 'should not create a draw cost request' do
          user = finance_user
          service = Projects::DrawCostRequestService.new(user: user, draw_cost: draw_cost)
          dcr = nil
          expect {
            dcr = service.create_request(valid_attributes)
          }.to raise_error(Projects::DrawCostRequestService::PolicyError)
        end

      end
      describe 'as a developer' do
        it 'should create a draw cost request and default submission' do
          user = developer_user
          service = Projects::DrawCostRequestService.new(user: user, draw_cost: draw_cost)
          dcr = nil
          expect {
            dcr = service.create_request(valid_attributes)
          }.to change{DrawCostRequest.count}
          refute(service.errors?)
          expect(service.draw_cost_request.draw_cost_submissions.count).to eq(1)
        end

      end
    end # without an existing request
    describe 'with invalid attributes' do
      it 'should not create a new draw cost request' do
        user = developer_user
        service = Projects::DrawCostRequestService.new(user: user, draw_cost: draw_cost)
        refute(service.errors?)
        dcr = nil
        expect {
          dcr = service.create_request(invalid_attributes)
        }.to_not change{DrawCostRequest.count}
        assert(service.errors?)
      end
    end
    describe 'with an existing request' do
      let(:new_request_attributes) {
        {
          amount: 12345.67,
          description: 'Test description',
          plan_change: true,
          plan_change_reason: 'Test reason'
        }
      }

      before do
        user = developer_user
        service = Projects::DrawCostRequestService.new(user: user, draw_cost: draw_cost)
        service.create_request(valid_attributes)
      end

      it 'should return the existing request instead of creating a new one' do
        existing_dcr = draw_cost.draw_cost_requests.order(created_at: :desc).first

        user = developer_user
        dcr = nil
        expect {
          service = Projects::DrawCostRequestService.new(user: user, draw_cost: draw_cost)
          dcr = service.create_request(valid_attributes)
        }.to_not change{DrawCostRequest.count}
        expect(dcr.id).to eq(existing_dcr.id)
      end
    end
  end # Create Draw Cost Request

  describe 'update request' do
    let(:valid_attributes) { valid_draw_cost_request_attributes }
    let(:new_request_attributes) {
      {
        amount: 212.67,
        description: 'Test description',
        plan_change: true,
        plan_change_reason: 'Test reason'
      }
    }
    let(:invalid_request_attributes) {
      {
        amount: nil,
        description: 'Test description',
        plan_change: true,
        plan_change_reason: 'Test reason'
      }
    }
    let(:existing_request) {
      user = developer_user
      service = Projects::DrawCostRequestService.new(user: user, draw_cost: draw_cost)
      service.create_request(valid_attributes)
    }

    before do
      existing_request
    end

    describe 'with an authorized user' do
      describe 'with valid attributes' do
        it 'should update the draw cost request' do
          user = developer_user
          service = Projects::DrawCostRequestService.new(user: user, draw_cost_request: existing_request)
          expect {
            service.update_request(new_request_attributes)
          }.to change{existing_request.amount}
        end
      end
      describe 'with invalid attributes' do
        it 'should not update the draw cost request' do
          user = developer_user
          service = Projects::DrawCostRequestService.new(user: user, draw_cost_request: existing_request)
          expect {
            service.update_request(invalid_request_attributes)
            existing_request.reload
          }.to_not change{existing_request.amount}
          assert(service.errors?)
        end
      end
    end
    describe 'with an unauthorized user' do
      it 'should raise an error' do
        user = consultant_user
        service = Projects::DrawCostRequestService.new(user: user, draw_cost_request: existing_request)
        old_amount = existing_request.amount
        expect {
          service.update_request(new_request_attributes)
        }.to raise_error(Projects::DrawCostRequestService::PolicyError)
        existing_request.reload
        expect(existing_request.amount).to eq(old_amount)
      end
    end
  end

  describe 'directly creating a draw cost submission' do
    let(:valid_attributes) { { amount: 1234.5 } }
    let(:invalid_attributes) { { amount: nil } }
    let(:request_service) { Projects::DrawCostRequestService.new(user: developer_user, draw_cost: draw_cost) }
    let(:draw_cost_request) { request_service.create_request(valid_draw_cost_request_attributes) }
    describe 'with an authorized user' do
      describe 'with valid attributes' do
        describe 'when there is a removed submission' do
          it 'creates a new submission' do
            old_submission = request_service.create_submission(draw_cost_request: draw_cost_request, params: valid_attributes)
            old_submission.remove!
            draw_cost_request.draw_cost_submissions.reload
            expect {
              new_submission = request_service.create_submission(draw_cost_request: draw_cost_request, params: valid_attributes)
            }.to change{DrawCostSubmission.count}
          end

        end # Removed submission
        describe 'when there is a no submission (unlikely)' do
          it 'creates a new submission' do
            draw_cost_request
            DrawCostSubmission.destroy_all
            new_submission = nil
            expect {
              new_submission = request_service.create_submission(draw_cost_request: draw_cost_request, params: valid_attributes)
            }.to change{DrawCostSubmission.count}
          end
        end # No submissions
        describe 'when there is a pending, submitted, or approved submission' do
          it 'does not create a new submission' do
            submission = request_service.create_submission(draw_cost_request: draw_cost_request, params: valid_attributes)
            new_submission = nil
            expect {
              new_submission = request_service.create_submission(draw_cost_request: draw_cost_request, params: valid_attributes)
            }.to_not change{DrawCostSubmission.count}
            expect(new_submission.id).to eq(submission.id)
          end
        end
      end
      describe 'with invalid attributes'
    end
    describe 'with an unauthorized user'
  end # Create Submission

  describe 'updating draw cost request submission' do
    let(:valid_attributes) { { amount: 1234.5 } }
    let(:invalid_attributes) { { amount: nil } }
    let(:request_service) { Projects::DrawCostRequestService.new(user: developer_user, draw_cost: draw_cost) }
    let(:draw_cost_request) { request_service.create_request(valid_draw_cost_request_attributes) }
    let(:submission) { draw_cost_request.draw_cost_submissions.first }

    describe 'with an authorized user' do
      let(:user) { developer_user }
      it 'will update the submission' do
        submission
        service = Projects::DrawCostRequestService.new(user: user, draw_cost_request: draw_cost_request)
        updated_submission = nil
        expect {
          updated_submission = service.update_submission(submission: submission, params: valid_attributes)
          submission.reload
        }.to change{submission.amount}
        refute(service.errors?)
        expect(submission.amount).to eq(valid_attributes[:amount])
      end
      describe 'with invalid attributes' do
        it 'will not update the submission' do
          submission
          old_amount = submission.amount
          service = Projects::DrawCostRequestService.new(user: user, draw_cost: draw_cost)
          updated_submission = nil
          expect {
            updated_submission = service.update_submission(submission: submission, params: invalid_attributes)
            submission.reload
          }.to_not change{submission.amount}
          assert(service.errors?)
          expect(submission.amount).to eq(old_amount)
        end
      end
    end # Updating a submission

    describe 'with an unauthorized user' do
      let(:user) { consultant_user }
      it 'will throw an error instead of updating the record' do
        draw_cost_request
        service = Projects::DrawCostRequestService.new(user: user, draw_cost: draw_cost)
        expect {
          service.update_submission(submission: submission, params: valid_attributes)
        }.to raise_error(Projects::DrawCostRequestService::PolicyError)
      end
    end
  end # Update submission

  describe 'remove submission' do
    let(:request_service) { Projects::DrawCostRequestService.new(user: developer_user, draw_cost: draw_cost) }
    let(:draw_cost_request) { request_service.create_request(valid_draw_cost_request_attributes) }
    let(:submission) { draw_cost_request.draw_cost_submissions.first }
    describe 'with an authorized user' do
      it 'should transition the submission to "removed"' do
        expect(submission.state).to eq('pending')
        user = developer_user
        service = Projects::DrawCostRequestService.new(user: user, draw_cost_request: draw_cost_request)
        service.remove_submission(submission)
        submission.reload
        expect(submission.state).to eq('removed')
      end

    end
    describe 'with an unauthorized user' do
      it 'should not change the submission state' do
        expect(submission.state).to eq('pending')
        user = consultant_user
        service = Projects::DrawCostRequestService.new(user: user, draw_cost_request: draw_cost_request)
        expect {
          service.remove_submission(submission)
        }.to raise_error(Projects::DrawCostRequestService::PolicyError)
        submission.reload
        expect(submission.state).to eq('pending')
      end
    end
  end # Remove submission

  describe 'approve request' do
    let(:draw_cost_request) {
      # Draw cost request with an approved submission
      service = Projects::DrawCostRequestService.new(user: developer_user, draw_cost: draw_cost)
      service.create_request(valid_draw_cost_request_attributes)
      submission = service.create_submission
      submission.update(state: :submitted)
      dcr = service.draw_cost_request
      dcr.reload
      service = Projects::DrawCostRequestService.new(user: manager_user, draw_cost_request: dcr)
      service.draw_cost_request
    }
    describe 'from submitted state' do
      describe 'with an authorized user' do
        let(:user) { manager_user }
        let(:service) {
          draw_cost_request.state = 'submitted'
          draw_cost_request.save!
          draw_cost_request.reload
          draw_cost_request.draw_cost_submissions.reload
          Projects::DrawCostRequestService.new(user: user, draw_cost_request: draw_cost_request)
        }

        before do
          service
        end

        it 'automatically approves submitted draw cost submissions' do
          expect(draw_cost_request.draw_cost_submissions.submitted.count).to eq(1)
          expect(draw_cost_request.draw_cost_submissions.approved.count).to eq(0)
          service.approve_request
          draw_cost_request.reload
          expect(draw_cost_request.draw_cost_submissions.submitted.count).to eq(0)
          expect(draw_cost_request.draw_cost_submissions.approved.count).to eq(1)
        end

        it 'approves the request' do
          assert(draw_cost_request.submitted?)
          refute(draw_cost_request.approver.present?)
          refute(draw_cost_request.approved_at.present?)
          service.approve_request
          refute(service.errors?)
          draw_cost_request.reload
          assert(draw_cost_request.approved?)
          expect(draw_cost_request.approver).to eq(user)
          assert(draw_cost_request.approved_at.present?)
        end

        describe 'with the finance project role' do
          describe 'if the request is clean' do
            it 'approves the request'
          end
          describe 'if the request is not clean' do
            it 'does not approve the request'
          end
        end

      end

      describe 'with an unauthorized user' do
        let(:user) { developer_user }
        let(:service) {
          draw_cost_request.state = 'submitted'
          draw_cost_request.save!
          Projects::DrawCostRequestService.new(user: user, draw_cost_request: draw_cost_request)
        }

        before do
          service
        end

        it 'throws an error instead of approving the request' do
          assert(draw_cost_request.submitted?)
          refute(draw_cost_request.approver.present?)
          refute(draw_cost_request.approved_at.present?)
          expect {
            service.approve_request
          }.to raise_error(Projects::DrawCostRequestService::PolicyError)
          refute(draw_cost_request.approved?)
          expect(draw_cost_request.approver).to be_nil
          refute(draw_cost_request.approved_at.present?)
        end
      end

    end
    describe 'from rejected state' do
      let(:user) { manager_user }
      let(:service) {
        draw_cost_request.state = 'rejected'
        draw_cost_request.save!
        create(:draw_cost_submission, draw_cost_request: draw_cost_request, state: :approved, amount: 1.0)
        draw_cost_request.reload
        Projects::DrawCostRequestService.new(user: user, draw_cost_request: draw_cost_request)
      }

      before do
        service
      end

      it 'approves the request' do
        assert(draw_cost_request.rejected?)
        refute(draw_cost_request.approver.present?)
        refute(draw_cost_request.approved_at.present?)
        service.approve_request
        refute(service.errors?)
        draw_cost_request.reload
        assert(draw_cost_request.approved?)
        expect(draw_cost_request.approver).to eq(user)
        assert(draw_cost_request.approved_at.present?)
      end
    end

    describe 'from a non-approvable state' do
      let(:user) { manager_user }
      let(:service) {
        draw_cost_request.state = 'pending'
        draw_cost_request.save!
        Projects::DrawCostRequestService.new(user: user, draw_cost_request: draw_cost_request)
      }

      before do
        service
      end

      it 'does not approve the request' do
        assert(draw_cost_request.pending?)
        refute(draw_cost_request.approver.present?)
        refute(draw_cost_request.approved_at.present?)
        service.approve_request
        assert(service.errors?)
        draw_cost_request.reload
        refute(draw_cost_request.approved?)
        expect(draw_cost_request.approver).to be_nil
        refute(draw_cost_request.approved_at.present?)
      end

    end
  end # Approve request

  describe 'reject request' do
    let(:draw_cost_request) {
      service = Projects::DrawCostRequestService.new(user: developer_user, draw_cost: draw_cost)
      service.create_request(valid_draw_cost_request_attributes)
    }
    describe 'from submitted state' do
      describe 'with an authorized user' do
        let(:user) { manager_user }
        let(:service) {
          draw_cost_request.state = 'submitted'
          draw_cost_request.save!
          create(:draw_cost_submission, draw_cost_request: draw_cost_request, state: :approved, amount: 1.0)
          draw_cost_request.reload
          Projects::DrawCostRequestService.new(user: user, draw_cost_request: draw_cost_request)
        }

        before do
          DrawCostRequest.destroy_all
          service
        end

        it 'rejects the request' do
          assert(draw_cost_request.submitted?)
          refute(draw_cost_request.approver.present?)
          refute(draw_cost_request.approved_at.present?)
          service.reject_request
          refute(service.errors?)
          draw_cost_request.reload
          assert(draw_cost_request.rejected?)
          expect(draw_cost_request.approver).to be_nil
          refute(draw_cost_request.approved_at.present?)
        end

      end

      describe 'with an unauthorized user' do
        let(:user) { developer_user }
        let(:service) {
          draw_cost_request.state = 'submitted'
          draw_cost_request.save!
          Projects::DrawCostRequestService.new(user: user, draw_cost_request: draw_cost_request)
        }

        before do
          service
        end

        it 'throws an error instead of rejecting the request' do
          assert(draw_cost_request.submitted?)
          refute(draw_cost_request.approver.present?)
          refute(draw_cost_request.approved_at.present?)
          expect {
            service.reject_request
          }.to raise_error(Projects::DrawCostRequestService::PolicyError)
          assert(draw_cost_request.submitted?)
          expect(draw_cost_request.approver).to be_nil
          refute(draw_cost_request.approved_at.present?)
        end
      end

    end

    describe 'from a non-rejectable state' do
      let(:user) { manager_user }
      let(:service) {
        draw_cost_request.state = 'pending'
        draw_cost_request.save!
        Projects::DrawCostRequestService.new(user: user, draw_cost_request: draw_cost_request)
      }

      before do
        service
      end

      it 'does not reject the request' do
        assert(draw_cost_request.pending?)
        refute(draw_cost_request.approver.present?)
        refute(draw_cost_request.approved_at.present?)
        service.approve_request
        assert(service.errors?)
        draw_cost_request.reload
        refute(draw_cost_request.approved?)
        expect(draw_cost_request.approver).to be_nil
        refute(draw_cost_request.approved_at.present?)
      end

    end
  end # Reject request

  describe 'submit draw cost submission' do
    let(:draw_cost_request) {
      service = Projects::DrawCostRequestService.new(user: developer_user, draw_cost: draw_cost)
      service.create_request(valid_draw_cost_request_attributes)
    }
    let(:draw_cost_submission) {
      submission = draw_cost_request.draw_cost_submissions.pending.first
      submission.amount = 1.0
      submission.save
      submission
    }
    describe 'as a project developer from the same company' do
      it 'transitions to the "submitted" state' do
        service = Projects::DrawCostRequestService.new(user: developer_user, draw_cost_request: draw_cost_request)
        service.submit_submission(draw_cost_submission)
        assert(draw_cost_submission.submitted?)
      end
    end
    describe 'as an authorized user' do
      it 'transitions to the "submitted" state' do
        service = Projects::DrawCostRequestService.new(user: owner_user, draw_cost_request: draw_cost_request)
        service.submit_submission(draw_cost_submission)
        assert(draw_cost_submission.submitted?)
      end
    end
    describe 'as an unauthorized user' do
      it 'remains in the same state' do
        user = draw_cost_request.project.developers.select{|u| u.organization_id != developer_user.organization_id}.first
        service = Projects::DrawCostRequestService.new(user: user, draw_cost_request: draw_cost_request)
        expect {
          service.submit_submission(draw_cost_submission)
        }.to raise_error(Projects::DrawCostRequestService::PolicyError)
        refute(draw_cost_submission.submitted?)
      end

    end
  end # Submit draw cost submission

  describe 'submit draw cost request' do
    let(:draw_cost_request) {
      service = Projects::DrawCostRequestService.new(user: developer_user, draw_cost: draw_cost)
      dcr = service.create_request(valid_draw_cost_request_attributes)
      dcs = dcr.draw_cost_submissions.first
      dcs.update(state: :submitted, amount: 1.0)
      dcr.reload
      dcr
    }
    describe 'as developer from the same organization' do
      it 'transitions the request to "submitted"' do
        service = Projects::DrawCostRequestService.new(user: developer_user, draw_cost_request: draw_cost_request)
        service.submit_request
        draw_cost_request.reload
        assert(draw_cost_request.submitted?)
      end
      it 'transitions any pending draw cost submissions to "submitted"' do
        draw_cost_request.draw_cost_submissions.update(state: :pending)
        draw_cost_request.draw_cost_submissions.reload
        expect(draw_cost_request.draw_cost_submissions.pending.count).to eq(1)
        expect(draw_cost_request.draw_cost_submissions.submitted.count).to eq(0)
        service = Projects::DrawCostRequestService.new(user: developer_user, draw_cost_request: draw_cost_request)
        service.submit_request
        draw_cost_request.reload
        assert(draw_cost_request.submitted?)
        expect(draw_cost_request.draw_cost_submissions.submitted.count).to eq(1)
      end
    end

    describe 'as an authorized user' do
      it 'transitions the request to "submitted"' do
        service = Projects::DrawCostRequestService.new(user: owner_user, draw_cost_request: draw_cost_request)
        service.submit_request
        draw_cost_request.reload
        assert(draw_cost_request.submitted?)
      end
    end
    describe 'as an unauthorized user' do
      it 'throws an error and does not transition the request state' do
        service = Projects::DrawCostRequestService.new(user: developer_user_other_organization, draw_cost_request: draw_cost_request)
        expect {
          service.submit_request
        }.to raise_error(Projects::DrawCostRequestService::PolicyError)
        draw_cost_request.reload
        refute(draw_cost_request.submitted?)
      end
    end
  end # Submit draw cost request

  describe 'approve draw cost submission' do
    let(:draw_cost_request) {
      service = Projects::DrawCostRequestService.new(user: developer_user, draw_cost: draw_cost)
      dcr = service.create_request(valid_draw_cost_request_attributes)
      dcr.update(state: :submitted, amount: 1.0)
      dcs = dcr.draw_cost_submissions.first
      dcs.update(state: :submitted, amount: 1.0)
      dcr.reload
      dcr
    }
    let(:draw_cost_submission) { draw_cost_request.draw_cost_submissions.first }
    describe 'by an authorized user' do
      let(:service) { Projects::DrawCostRequestService.new(user: manager_user, draw_cost_request: draw_cost_request) }
      describe 'when the submission is pending' do
        it 'does not change the state and the service returns errors' do
          draw_cost_submission.update(state: :pending)
          draw_cost_request.draw_cost_submissions.reload
          service.approve_submission(draw_cost_submission)
          draw_cost_submission.reload
          assert(service.errors?)
          assert(draw_cost_submission.pending?)
        end
      end
      describe 'when the submission is submitted' do
        it 'approves the submission' do
          service.approve_submission(draw_cost_submission)
          draw_cost_submission.reload
          refute(service.errors?)
          assert(draw_cost_submission.approved?)
        end
      end
      describe 'when the submission is already approved' do
        it 'does nothing' do
          draw_cost_submission.update(state: :approved)
          draw_cost_request.draw_cost_submissions.reload
          service.approve_submission(draw_cost_submission)
          draw_cost_submission.reload
          refute(service.errors?)
          assert(draw_cost_submission.approved?)
        end
      end
      describe 'when the submission is rejected' do
        it 'does not change the state and the service returns errors' do
          draw_cost_submission.update(state: :rejected)
          draw_cost_request.draw_cost_submissions.reload
          service.approve_submission(draw_cost_submission)
          draw_cost_submission.reload
          assert(service.errors?)
          assert(draw_cost_submission.rejected?)
        end
      end
      describe 'when the submission is removed' do
        it 'does not change the state and the service returns errors' do
          draw_cost_submission.update(state: :removed)
          draw_cost_request.draw_cost_submissions.reload
          service.approve_submission(draw_cost_submission)
          draw_cost_submission.reload
          assert(service.errors?)
          assert(draw_cost_submission.removed?)
        end
      end
    end
    describe 'by an unauthorized user' do
      let(:service) { Projects::DrawCostRequestService.new(user: developer_user, draw_cost_request: draw_cost_request) }
      it 'throws an error and does not transition the draw cost submission' do
        expect {
          service.approve_submission(draw_cost_submission)
        }.to raise_error(Projects::DrawCostRequestService::PolicyError)
        draw_cost_submission.reload
        assert(draw_cost_submission.submitted?)
      end
    end
  end # Approve submission

end
