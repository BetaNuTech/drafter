class DrawCostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_draw
  before_action :set_draw_cost, only: %i[ show edit update destroy ]
  after_action :verify_authorized

  def index
    authorize DrawCost.new(draw: @draw)
  end

  def new
    @service = DrawCostService.new(user: @current_user, draw: @draw)
    authorize @service.draw_cost
    breadcrumbs.add(label: 'Home', url: '/')
    breadcrumbs.add(label: @service.project.name, url: project_path(@service.project))
    breadcrumbs.add(label: @service.draw.name, url: project_draw_path(project_id: @service.project.id, id: @service.draw.id))
    breadcrumbs.add(label: 'New Draw Cost', active: true)
  end

  def create
    @service = DrawCostService.new(user: @current_user, draw: @draw)
    authorize @service.draw_cost

    @draw_cost = @service.create(params[:draw_cost])
    if @service.errors?
      render :new, status: :unprocessable_entity
    else
      redirect_to project_draw_path(project_id: @service.project.id, id: @service.draw.id), notice: 'Created new Draw Cost'
    end
  end

  def edit
    authorize @draw_cost
    @service = DrawCostService.new(user: @current_user, draw: @draw_cost.draw, draw_cost: @draw_cost)
  end

  def update
    authorize @draw_cost
    @service = DrawCostService.new(user: @current_user, draw: @draw_cost.draw, draw_cost: @draw_cost)
    @service.update(params[:draw_cost])
    if @service.errors?
      render :edit, status: :unprocessable_entity
    else
      redirect_to project_draw_path(project_id: @service.project.id, id: @service.draw.id), notice: 'Updated Draw Cost'
    end
  end

  private

  def draw_record_scope
    DrawPolicy::Scope.new(@current_user, Draw).resolve
  end

  def record_scope
    @draw.draw_costs
  end

  def set_draw
    @draw = draw_record_scope.find(params[:draw_id])
  end

  def set_draw_cost
    @draw_cost = record_scope.find(params[:id])
  end
  
end
