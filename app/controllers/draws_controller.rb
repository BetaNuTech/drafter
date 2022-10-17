class DrawsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_draw, except: %i[index new]
  after_action :verify_authorized

  def index
    authorize Draw.new(project: @project)
    @service = Projects::DrawService.new(current_user: @current_user, project: @project)
    @draws = @service.draws
    breadcrumbs.add(label: 'Home', url: '/')
    breadcrumbs.add(label: @project.name, url: project_path(@project))
    breadcrumbs.add(label: 'Draws')
  end

  def show
    authorize @draw
    #@draw_cost_requests = policy_scope(@draw.draw_cost_requests)
    #@total_cost = @draw_cost_requests.map(&:provisional_total).sum
    #@difference_to_amounts = @draw_cost_requests.map(&:difference_to_amount).sum
    breadcrumbs.add(label: 'Home', url: '/')
    breadcrumbs.add(label: @project.name, url: project_path(@project))
    breadcrumbs.add(label: 'Draws' )
    breadcrumbs.add(label: @draw.name, url: project_draw_path(project_id: @project.id), active: true)
  end

  def new
    @service = DrawService.new(user: @current_user, project: @project)
    authorize @service.draw
    breadcrumbs.add(label: 'Home', url: '/')
    breadcrumbs.add(label: @project.name, url: project_path(@project))
    breadcrumbs.add(label: 'New Draw', url: new_project_draw_path(project_id: @project.id), active: true)
  end

  def edit
    @service = DrawService.new(user: @current_user, project: @project, draw: @draw)
    authorize @service.draw
    breadcrumbs.add(label: 'Home', url: '/')
    breadcrumbs.add(label: @project.name, url: project_path(@project))
    breadcrumbs.add(label: 'Edit Draw', url: edit_project_draw_path(project_id: @project.id), active: true)
  end

  def create
    @service = DrawService.new(user: @current_user, project: @project)
    authorize @service.draw
    @draw = @service.create(params[:draw])
    if @service.errors?
      render :new, status: :unprocessable_entity
    else
      respond_to do |format|
        format.html { redirect_to project_draw_path(project_id: @project, id: @draw.id), notice: 'created new draw'}
        format.turbo_stream
      end
    end
    
  end

  def update
    authorize @draw
    @service = DrawService.new(user: @current_user, project: @project, draw: @draw)
    @draw = @service.update(params[:draw])
    respond_to do |format|
      if @service.errors?
        format.html {
          render :edit, status: :unprocessable_entity
        }
      else
        format.html { redirect_to project_draws_path(project_id: @service.project.id, id: @service.draw.id), notice: "Draw was successfully updated." }
        format.turbo_stream
      end
    end
  end

  def destroy
    authorize @draw
    @service = DrawService.new(user: @current_user, project: @project, draw: @draw)

    # Withdraw Draw (soft delete)
    if @service.withdraw
      respond_to do |format|
        format.html { redirect_to project_path(id: @project.id), notice: "Draw was removed." }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def approve_internal
    authorize @draw
    @service = DrawService.new(user: @current_user, project: @project, draw: @draw)

    # Withdraw Draw (soft delete)
    if @service.withdraw
      respond_to do |format|
        format.html { redirect_to project_path(id: @project.id), notice: "Draw was removed." }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def record_scope
    @project.draws
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_draw
    @draw = record_scope.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def draw_params
    allowed_params = policy(Draw).allowed_params
    params.require(:draw).permit(*allowed_params)
  end

  def project_record_scope
    ProjectPolicy::Scope.new(@current_user, Project).resolve
  end

  def set_project
    @project ||= project_record_scope.find(params[:project_id])
  end
end
