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
        SystemEvent.log(description: "Added draw cost '#{@draw_cost.name}' for Draw '#{@draw.name}'", event_source: @project, incidental: @current_user, severity: :warn)
      respond_to do |format|
        format.html { redirect_to draw_draw_cost_path(draw_id: @draw_cost.draw_id, id: @draw_cost.id), notice: 'Added a new Draw Cost' }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    authorize @draw_cost
  end

  def edit
    authorize @draw_cost
  end

  def update
    authorize @draw_cost
    if @draw_cost.update(draw_cost_params)
      respond_to do |format|
        SystemEvent.log(description: "Updated draw cost '#{@draw_cost.name}' for Draw '#{@draw.name}'", event_source: @draw.project, incidental: @current_user, severity: :warn)
        format.html { redirect_to draw_draw_cost_path(draw_id: @draw_cost.draw_id, id: @draw_cost.id), notice: 'Updated Draw Cost' }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @draw_cost
    if @draw_cost.destroy
      respond_to do |format|
        SystemEvent.log(description: "Deleted draw cost '#{@draw_cost.name}' for Draw '#{@draw.name}'", event_source: @draw.project, incidental: @current_user, severity: :warn)
        format.html { redirect_to draw_path(@draw_cost.draw), notice: 'Draw cost deleted'}
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end

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
