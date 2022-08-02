class DrawCostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_draw
  before_action :set_draw_cost, only: %i[ show edit update destroy ]
  after_action :verify_authorized

  def index
    authorize new_draw_cost
    @draw_costs = DrawCost.where(draw: @draw)
  end

  def new
    @draw_cost = new_draw_cost
    authorize @draw_cost
  end

  def create
    @draw_cost = @draw.draw_costs.new(draw_cost_params)
    authorize @draw_cost
    if @draw_cost.save
      format.html { redirect_to draw_cost_cost_path(draw_id: @draw.id, id: @draw_cost.id), notice: 'Added a new Draw Cost' }
    else
      render :new, :unprocessable_entity
    end
  end

  def show
    authorize @draw_cost
  end

  private

  def new_draw_cost
    DrawCost.new(draw: @draw)
  end

  def record_scope
    @draw.draw_costs
  end

  def set_draw_cost
    @draw_cost = record_scope.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def draw_cost_params
    allowed_params = policy(DrawCost).allowed_params
    params.require(:draw_cost).permit(*allowed_params)
  end
  
  def draw_record_scope
    DrawPolicy::Scope.new(@current_user, Draw).resolve
  end

  def set_draw
    @draw ||= draw_record_scope.find(params[:draw_id]) if params[:draw_id].present?
  end


end
