class DrawCostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_draw_cost, only: %i[ show edit update destroy ]
  after_action :verify_authorized

  def index
    authorize new_draw_cost
    if params[:draw_id].present?
      @draws = @project.draws.where(id: params[:draw_id])
    else
      @draws = @project.draws
    end
    @draw_costs = DrawCost.where(draw: @draws)
  end

  private

  def new_draw_cost
    DrawCost.new(draw: Draw.new(project: @project))
  end

  def record_scope
    @project.draw_costs
  end

  def set_draw_cost
    @draw_cost = record_scope.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def draw_cost_params
    allowed_params = policy(DrawCost).allowed_params
    params.require(:draw_cost).permit(*allowed_params)
  end

  def project_record_scope
    ProjectPolicy::Scope.new(@current_user, Project).resolve
  end

  def set_project
    @project ||= project_record_scope.find(params[:project_id])
  end

end
