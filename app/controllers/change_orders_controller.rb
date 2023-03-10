class ChangeOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_draw_cost
  before_action :set_change_order, except: %i{index new create}
  after_action :verify_authorized

  def index
    authorize ChangeOrder.new(draw_cost: @draw_cost)
    raise ActiveRecord::RecordNotFound
  end

  def new
    @change_order = ChangeOrder.new(draw_cost: @draw_cost, amount: @draw_cost.project_cost_overage)
    authorize @change_order
  end

  def create
    @service = ChangeOrderService.new(user: @current_user, draw_cost: @draw_cost)
    authorize @service.change_order
    @change_order = @service.create(params[:change_order])
    @draw_cost.change_orders.reload
    @related_draw_cost = @change_order.draw.project.draw_costs.where(project_cost: @change_order.funding_source).first
    if @service.errors?
      render :new, status: :unprocessable_entity
    else
      respond_to do |format|
        format.html {
          redirect_to project_draw_path(project_id: @draw_cost.project.id, id: @draw_cost.draw_id)
        }
        format.turbo_stream
      end
    end
  end

  def destroy
    authorize @change_order
    @related_draw_cost = @change_order.draw.project.draw_costs.where(project_cost: @change_order.funding_source).first
    @service = ChangeOrderService.new(user: @current_user, change_order: @change_order)
    @service.destroy
    respond_to do |format|
      format.html {
        redirect_to project_draw_path(project_id: @draw_cost.project.id, id: @draw_cost.draw_id)
      }
      format.turbo_stream
    end
  end

  def approve
    authorize @change_order
    @service = ChangeOrderService.new(user: @current_user, draw_cost: @draw_cost, change_order: @change_order)
    @service.approve
    @change_order.reload
    @draw_cost.draw.draw_costs.reload
    @related_draw_cost = @change_order.draw.project.draw_costs.where(project_cost: @change_order.funding_source).first
    respond_to do |format|
      format.html { redirect_to draw_draw_cost_path(draw_id: @draw_cost.draw_id, id: @draw_cost.id)}
      format.turbo_stream
    end
  end

  def reject
    authorize @change_order
    @service = ChangeOrderService.new(user: @current_user, draw_cost: @draw_cost, change_order: @change_order)
    @service.reject
    @change_order.reload
    @draw_cost.draw.draw_costs.reload
    @related_draw_cost = @change_order.draw.project.draw_costs.where(project_cost: @change_order.funding_source).first
    respond_to do |format|
      format.html { redirect_to draw_draw_cost_path(draw_id: @draw_cost.draw_id, id: @draw_cost.id)}
      format.turbo_stream
    end
  end

  def reset_approval
    authorize @change_order
    @service = ChangeOrderService.new(user: @current_user, draw_cost: @draw_cost, change_order: @change_order)
    @service.reset_approval
    @change_order.reload
    @draw_cost.draw.draw_costs.reload
    @related_draw_cost = @change_order.draw.project.draw_costs.where(project_cost: @change_order.funding_source).first
    respond_to do |format|
      format.html { redirect_to draw_draw_cost_path(draw_id: @draw_cost.draw_id, id: @draw_cost.id)}
      format.turbo_stream
    end
  end

  private

  def draw_cost_record_scope
    DrawCostPolicy::Scope.new(@current_user, DrawCost).resolve
  end

  def set_draw_cost
    @draw_cost = draw_cost_record_scope.find(params[:draw_cost_id])
  end

  def record_scope
    @draw_cost.change_orders
  end

  def set_change_order
    @change_order = record_scope.find(params[:id] || params[:change_order_id])
  end

  
end
