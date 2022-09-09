class DrawCostRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_draw_cost_request, only: %i[ show edit update destroy ]
  after_action :verify_authorized

  def index
    authorize DrawCostRequest
    @collection = record_scope.order(created_at: :desc) 
  end

  def new
    # TODO
    authorize DrawCostRequest
    @draw_cost_request = DrawCostRequest.new()
  end

  private

  def record_scope
    policy_scope(DrawCostRequest)
  end

  def set_draw_cost_request
    @draw_cost_request = record_scope.find(params[:id])
  end

  def draw_cost_request_params
    allowed_params = policy(@draw_cost_request||DrawCostRequest).allowed_params
    params.require(:draw_cost_request).permit(*allowed_params)
  end

end
