class DrawsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_draw, only: %i[ show edit update destroy ]
  after_action :verify_authorized

  def index
    authorize Draw
    @service = Projects::DrawService.new(current_user: @current_user, project: @project)
    @draws = @service.draws
  end

  def show
    authorize @draw
  end

  def new
    @service = Projects::DrawService.new(current_user: @current_user, project: @project)
    authorize @service.draw
  end

  def edit
    @service = Projects::DrawService.new(current_user: @current_user, project: @project, draw: @draw)
    authorize @service.draw
  end

  def create
    @service = Projects::DrawService.new(current_user: @current_user, project: @project)
    authorize @service.draw
    if @service.create(params)
      respond_to do |format|
        format.html { redirect_to project_draws_path(project_id: @service.project.id), notice: 'Drawed new draw'}
        format.turbo_stream
      end
    else
      render :new, :unprocessable_entity
    end
    
  end

  def update
    @service = Projects::DrawService.new(current_user: @current_user, project: @project, draw: @draw)
    authorize @service.draw
    respond_to do |format|
      if @service.update(params)
        format.html { redirect_to project_draws_path(project_id: @service.project.id, id: @service.draw.id), notice: "Draw was successfully updated." }
      else
        render :edit, :unprocessable_entity
      end
    end
  end

  def destroy
    @service = Projects::DrawService.new(current_user: @current_user, project: @project, draw: @draw)
    authorize @service.draw

    if @service.destroy
      respond_to do |format|
        format.html { redirect_to draws_url, notice: "Draw was successfully destroyed." }
        format.turbo_stream
      end
    else
      render :edit, :unprocessable_entity
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
