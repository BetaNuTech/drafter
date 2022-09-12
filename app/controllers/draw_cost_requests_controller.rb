class DrawCostRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_draw, only: %i[new create]
  before_action :set_draw_cost_request, only: %i[ show edit update destroy ]
  before_action :set_project, only: %i[new create show edit update]
  after_action :verify_authorized

  def index
    authorize DrawCostRequest
    @collection = record_scope.order(created_at: :desc) 
    # TODO: view
  end

  def new
    @draw_cost_request = DrawCostRequest.new(user: @current_user, organization: @current_user.organization, draw: @draw)
    authorize @draw_cost_request
    breadcrumbs.add(label: 'Home', url: '/')
    breadcrumbs.add(label: @project.name, url: project_path(@project))
    breadcrumbs.add(label: @draw.name, url: draw_path(project_id: @project.id, id: @draw.id))
    breadcrumbs.add(label: 'New Request', url: new_draw_draw_cost_request_path(draw_id: @draw.id), active: true)
  end

  def create
    @draw_cost_request = DrawCostRequest.new(user: @current_user, organization: @current_user.organization, draw: @draw)
    authorize @draw_cost_request
    @service = Projects::DrawCostRequestService.new(user: @current_user, draw: @draw, draw_cost: @draw_cost)
    @draw_cost_request = @service.create_request(params)
    if @service.errors?
      render :new, status: :unprocessable_entity
    else
      redirect_to project_draw_path(project_id: @service.project.id, id: @service.draw.id) 
    end
  end

  def show
    authorize @draw_cost_request
    # TODO: view
  end

  def edit
    authorize @draw_cost_request
    service = Projects::DrawCostRequestService.new(user: @current_user, draw_cost_request: @draw_cost_request)
    # TODO: view
  end

  def destroy
    authorize @draw_cost_request
    @draw = @draw_cost_request.draw
    @draw_cost_request.destroy
    redirect_to draw_path(draw: @draw), notice: 'Removed Draw Cost Request'
  end

  private

  def draw_scope
    DrawPolicy::Scope.new(@current_user, Draw).resolve
  end

  def set_draw
    @draw = draw_scope.find(params[:draw_id])
  end

  def set_project
    @project = ( @draw || @draw_cost_request ).project
  end

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
