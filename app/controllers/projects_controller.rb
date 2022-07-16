class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [:edit, :update, :show, :destroy]
  after_action :verify_authorized

  def index
    authorize Project
    @collection = record_scope.order(name: :asc)
  end

  def new
    @project = Project.new
    authorize @project
  end

  def create
    @project = Project.new(project_params)
    authorize @project
    respond_to do |format|
      if @project.save
        format.html { redirect_to project_path(@project), notice: 'Created new project'}
      else
        format.html { render :new }
      end
    end
  end

  def show
    authorize @project
  end

  def edit
    authorize @project
  end

  def update
    authorize @project
    respond_to do |format|
      if @project.update(project_params)
        format.html { redirect_to project_path(@project), notice: 'Updated project' }
      else
        format.html { render :edit }
      end
    end
  end


  def destroy
    authorize @project
    @project.destroy
    respond_to do |format|
      format.html { redirect_to projects_path, notice: 'Removed project' }
    end
  end

  private

  def record_scope
    policy_scope(Project)
  end

  def set_project
    @project = record_scope.find(params[:id])
  end

  def project_params
    allowed_params = policy(Project).allowed_params
    params.require(:project).permit(*allowed_params)
  end
end
