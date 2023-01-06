class ProjectTasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project_task, except: %i[index new create]
  after_action :verify_authorized

  # GET /project_tasks
  def index
    # NOT IMPLEMENTED
    authorize ProjectTask
  end

  # GET /project_tasks/new
  def new
    # NOT IMPLEMENTED
    authorize ProjectTask
  end

  # POST /project_tasks/new
  def create
    # NOT IMPLEMENTED
    authorize ProjectTask
  end

  # GET /project_tasks/:id
  def show
    authorize @project_task
  end

  # GET /project_tasks/:id/edit
  def edit
    # NOT IMPLEMENTED
    authorize ProjectTask
  end

  # PATCH /project_tasks/:id
  def update
    # NOT IMPLEMENTED
    authorize ProjectTask
  end

  # DELETE /project_tasks/:id
  def destroy
    # NOT IMPLEMENTED
    authorize ProjectTask
  end

  # POST /project_tasks/:id/verify
  def verify
    authorize @project_task
    service = ProjectTaskService.new(@project_task)
    service.verify
    if service.errors?
      render :show, status: :unprocessable_entity, notice: 'Error Verifying Task Item'
    else
      respond_to do |format|
        format.html { redirect_to url_for(@project_task), notice: 'Verified Task Item'}
        format.turbo_stream
      end
    end
  end

  # POST /project_tasks/:id/reject
  def reject
    authorize @project_task
    service = ProjectTaskService.new(@project_task)
    service.reject
    if service.errors?
      render :show, status: :unprocessable_entity, notice: 'Error rejecting Task Item'
    else
      respond_to do |format|
        format.html { redirect_to url_for(@project_task), notice: 'Rejected Task Item'}
        format.turbo_stream
      end
    end
  end

  # POST /project_tasks/:id/archive
  def archive
    authorize @project_task
    service = ProjectTaskService.new(@project_task)
    service.archive
    if service.errors?
      render :show, status: :unprocessable_entity
    else
      respond_to do |format|
        format.html { redirect_to url_for(@project_task), notice: 'Archived Task'}
        format.turbo_stream
      end
    end
  end
  
  private

  def project_task_scope
    ProjectTaskPolicy::Scope.new(@current_user, ProjectTask).resolve
  end

  def set_project_task
    @project_task = project_task_scope.find(params[:id] || params[:project_task_id])
  end
end
