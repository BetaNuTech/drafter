module Projects
  class DrawCostRequestService
    attr_reader :project, :current_user, :user, :draw, :draw_cost, :organization, :draw_cost_request, :errors

    class PolicyError < StandardError; end

    def initialize(user: , draw_cost: nil, draw_cost_request: nil)
      @user = user
      @organization = @user.organization
      if draw_cost_request
        @draw_cost_request = draw_cost_request
        @draw_cost = @draw_cost_request.draw_cost
        @draw = @draw_cost.draw
      else
        @draw_cost = draw_cost
        @draw = @draw_cost.draw
        @draw_cost_request = DrawCostRequest.new(draw: @draw, draw_cost: @draw_cost)
      end
      @request_policy = DrawCostRequestPolicy.new(@user, @draw_cost_request)
      raise PolicyError.new unless @request_policy.index?
      @errors = []
    end

    # Return existing non-rejected request
    def create_request(params)
      raise PolicyError.new unless @request_policy.create?

      reset_errors
      existing_dcr = existing_request
      if existing_dcr.present?
        @draw_cost_request = existing_dcr
      else
        override_params = {
          draw_cost: @draw_cost,
          draw: @draw,
          user: @user,
          organization: @organization,
          state: 'pending',
          audit: false,
          approval_due_date: Date.current + [ @draw_cost.approval_lead_time, 15 ].min.days
        }
        effective_params = sanitize_request_params(params).merge(override_params)
        @draw_cost_request = DrawCostRequest.new(effective_params)
        unless @draw_cost_request.save
          @errors = @draw_cost_request.errors.full_messages
          return @draw_cost_request
        end
      end

      return @draw_cost_request if @draw_cost_request.draw_cost_submissions.any?

      create_submission
      @draw_cost_request.reload
      @draw_cost_request
    end

    def update_request(params)
      raise PolicyError.new unless @request_policy.update?

      reset_errors
      unless @draw_cost_request.update(sanitize_request_params(params))
        @errors = @draw_cost_request.errors.full_messages
      end
      return @draw_cost_request
    end

    def submit_request
      # TODO
      # submit pending request submissions having a specified amount
      # submit request
    end

    def approve_request
      raise PolicyError.new unless @request_policy.approve?

      reset_errors

      if @draw_cost_request.draw_cost_submissions.submitted.any?
        @draw_cost_request.draw_cost_submissions.submitted.each do |dcs|
          dcs.trigger_event(event_name: :approve, user: @user)
        end
        @draw_cost_request.draw_cost_submissions.reload
      end

      if @draw_cost_request.draw_cost_submissions.approved.any?
        if @draw_cost_request.permitted_state_events.include?(:approve)
          @draw_cost_request.trigger_event(event_name: :approve, user: @user)
        else
          @errors = ["The Draw Cost Request is not in an approvable state"]
        end
      else
        @errors = ["The Draw Cost Request doesn't have any approved submissions"]
      end

      @draw_cost_request
    end

    def reject_request
      raise PolicyError.new unless @request_policy.approve?

      reset_errors
      if @draw_cost_request.permitted_state_events.include?(:approve)
        @draw_cost_request.trigger_event(event_name: :reject, user: @user)
      else
        @errors = ['Draw Cost is not in a rejectable state']
      end

      @draw_cost_request
    end

    def create_submission(draw_cost_request: @draw_cost_request, params: { amount: 0.0} )
      raise PolicyError.new unless @request_policy.create?

      pending_submission = @draw_cost_request.draw_cost_submissions.pending.order(created_at: :desc).first
      return pending_submission if pending_submission.present?

      submitted_submission = @draw_cost_request.draw_cost_submissions.submitted.order(created_at: :desc).first
      return submitted_submission if submitted_submission.present?

      approved_submission = @draw_cost_request.draw_cost_submissions.approved.order(created_at: :desc).first
      return approved_submission if approved_submission.present?

      reset_errors
      submission = DrawCostSubmission.create(draw_cost_request: @draw_cost_request, amount: 0.0)
      @draw_cost_request.draw_cost_submissions.reload
      submission
    end

    def update_submission(submission:, params:)
      raise PolicyError.new unless submission_policy(submission).create?

      reset_errors
      if submission.update(sanitize_submission_params(submission, params))
        @draw_cost_request.draw_cost_submissions.reload
      else
        @errors = submission.errors.full_messages
      end

      return submission
    end

    def submit_submission(submission)
      raise PolicyError.new unless submission_policy(submission).submit?

      submission.trigger_event(event_name: :submit, user: @user)
      submission
    end

    def remove_submission(draw_cost_submission)
      raise PolicyError.new unless submission_policy(draw_cost_submission).remove?

      draw_cost_submission.trigger_event(event_name: :remove, user: @user)
      draw_cost_submission
    end

    def approve_submission(submission)
      raise PolicyError.new unless submission_policy(submission).approve?

      reset_errors
      if submission.permitted_state_events.include?(:approve)
        submission.trigger_event(event_name: :approve, user: @user)
      else
        @errors = ['Submission is not in an approvable state']
      end

      @draw_cost_request.draw_cost_submissions.reload

      submission
    end

    def add_document(params)
      # TODO
    end

    def remove_document(params)
      # TODO
    end

    def approve_document(document)
      # TODO
    end

    def reject_document(document)
      # TODO
    end



    def errors?
      @errors.present?
    end

    private

    def reset_errors
      @errors = []
    end

    def existing_request
      @draw_cost.draw_cost_requests.
        where(organization: @organization, state: DrawCostRequest::EXISTING_STATES).
        order(created_at: :asc).
        limit(1).first
    end

    def sanitize_request_params(params)
      allowed_params = @request_policy.allowed_params
      if params.is_a?(ActionController::Parameters)
        params.require(:draw_cost_request).permit(*allowed_params)
      else
        params.select{|k,v| allowed_params.include?(k.to_sym) }
      end
    end

    def submission_policy(submission)
      DrawCostSubmissionPolicy.new(@user, submission)
    end

    def sanitize_submission_params(submission, params)
      allowed_params = submission_policy(submission).allowed_params
      if params.is_a?(ActionController::Parameters)
        params.require(:draw_cost_submission).permit(*allowed_params)
      else
        params.select{|k,v| allowed_params.include?(k.to_sym) }
      end
    end

  end
end
