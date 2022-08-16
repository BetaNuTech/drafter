module Projects
  class DrawCostRequestService
    attr_reader :project, :current_user, :user, :draw, :organization, :draw_cost_request

    def initialize(current_user: nil, draw:)
      @current_user = current_user
      @user = @current_user
      @organization = @user.organization
      @draw = draw
      @draw_cost_request = DrawCostRequest.new(draw: @draw)
      @policy = DrawCostRequestPolicy.new(current_user, @draw_cost_request)
      @errors = []
    end

    # Return existing non-rejected request
    def create_request(params)
      # TODO
      existing_dcr = existing_request
      if existing_dcr.present?
        @draw_cost_request = existing_dcr
        return @draw_cost_request
      end

      override_params = {
        user: @current_user,
        organization: @current_organization,
        state: 'pending',
        audit: false
      }
      effective_params =  sanitized_params(params).merge(override_params)
      @draw_cost_request = DrawCostRequest.new(effective_params)
      unless @draw_cost_request.save
       @errors = @draw_cost_request.errors.full_messages
       return @draw_cost_request
      end

      # TODO initialize submission

    end

    def update_request(draw_cost_request)
      @draw_cost_request = draw_cost_request
      # TODO
    end

    def create_submission
      # TODO
    end

    def update_submission
      # TODO
    end

    def errors?
      @errors.present?
    end

    private

    def existing_request
      @draw.draw_cost_requests.
        where(organization: @organization, state: DrawCostRequest::EXISTING_STATES).
        order(created_at: :asc).
        limit(1).first
    end

    def sanitize_params(params)
      allowed_params = @policy.allowed_params
      if params.is_a?(ActionController::Parameters)
        params.require(:draw_cost_request).permit(*allowed_params)
      else
        params.select{|k,v| allowed_params.include?(k.to_s) }
      end
    end

  end
end
