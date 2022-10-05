class DrawCostSubmissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_draw_cost_request
  before_action :set_draw_cost_submission, only: %w[show edit update destroy]
  after_action :verify_authorized

  # GET #index disabled
  def index
    raise ActiveRecord::RecordNotFound
  end

  def new
    @draw_cost_submission = DrawCostSubmission.new(draw_cost_request: @draw_cost_request)
    authorize @draw_cost_submission 
  end

  def create
    auth_obj = DrawCostSubmission.new(draw_cost_request: @draw_cost_request)
    authorize auth_obj
    service = Projects::DrawCostRequestService.new(user: @current_user, draw_cost_request: @draw_cost_request)
    @draw_cost_submission = service.create_submission(draw_cost_request: @draw_cost_request, params: draw_cost_submission_params)
    @new_draw_cost_submission = DrawCostSubmission.new(draw_cost_request: @draw_cost_request)
    if service.errors?
      render :new, status: :unprocessable_entity
    else
      @draw_cost_request.draw_cost_submissions.reload
      respond_to do |format|
        format.html { redirect_to draw_cost_request_draw_cost_submission_url(draw_cost_request_id: @draw_cost_request.id, id: @draw_cost_submission.id) }
        format.turbo_stream
      end
    end
  end

  def show
    authorize @draw_cost_submission 
  end

  def edit
    authorize @draw_cost_submission 
  end

  def update
    # TODO: update totals on page
    authorize @draw_cost_submission 
    service = Projects::DrawCostRequestService.new(user: @current_user, draw_cost_request: @draw_cost_request)
    @draw_cost_submission = service.update_submission(submission: @draw_cost_submission, params: params)
    if service.errors?
      render :edit, status: :unprocessable_entity
    else
      redirect_to draw_cost_request_draw_cost_submission_path(draw_cost_request_id: @draw_cost_request.id, draw_cost_submission_id: @draw_cost_submission.id)
    end
  end

  def destroy
    # TODO
  end

  private
  
  def draw_cost_request_scope
    DrawCostRequestPolicy::Scope.new(@current_user, DrawCostRequest).resolve
  end

  def set_draw_cost_request
    @draw_cost_request = draw_cost_request_scope.find(params[:draw_cost_request_id])
  end

  def record_scope
    policy_scope(@draw_cost_request.draw_cost_submissions)
  end

  def set_draw_cost_submission
    @draw_cost_submission = record_scope.find(params[:id] || params[:draw_cost_submission_id])
  end

  def draw_cost_submission_params
    new_draw_cost_submission = DrawCostSubmission.new(draw_cost_request: @draw_cost_request)
    allowed_params = policy(@draw_cost_submission||new_draw_cost_submission).allowed_params
    params.require(:draw_cost_submission).permit(*allowed_params)
  end
end
