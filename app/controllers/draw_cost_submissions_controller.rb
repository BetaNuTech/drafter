class DrawCostSubmissionsController < ApplicationController
  before_action :authenticate_user
  before_action :set_draw_cost_request
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
    @draw_cost_submission = DrawCostSubmission.new(draw_cost_request: @draw_cost_request)
    authorize @draw_cost_submission
  end

  def show
    # TODO
  end

  def edit
    # TODO
  end

  def update
    # TODO
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
    @draw_cost_submission = record_scope.find(params[:id])
  end
end
