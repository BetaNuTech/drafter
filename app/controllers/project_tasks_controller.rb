class ProjectTasksController < ApplicationController
  before_action :authenticate_user!, except: %i{update_task}
  before_action :authenticate_service_token, only: %i{update_task}
  before_action :set_project_task, except: %i{ index new create update_task }
  after_action :verify_authorized, except: %i{update_task}

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

  # POST /project_tasks/:id/approve
  def approve
    authorize @project_task
    service = ProjectTaskService.new(@project_task)
    service.approve
    if service.errors?
      render :show, status: :unprocessable_entity, notice: 'Error Approving Task Item'
    else
      respond_to do |format|
        format.html { redirect_to url_for(@project_task), notice: 'Approving Task Item'}
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

  # POST /project_tasks/update_task.json?id=XXX&token=XXX&status=XXX
  # !!! Only accepts JSON requests !!!
  #
  def update_task
    remoteid = params[:id] || params[:remoteid] || nil
    raise ActiveRecord::RecordNotFound unless remoteid.present?

    @project_task = ProjectTask.where(remoteid: remoteid).first
    raise ActiveRecord::RecordNotFound unless @project_task.present?

    force = params[:force] || false

    if force
      # Update project_task state now
      status = params[:status] || ''
      service = ProjectTaskService.new(@project_task)
      result = service.update_status(status)
    else
      # Mark project_task for status update
      project_task.remote_updated_at = nil
      project_task.save
    end

    respond_to do |format|
      format.json do
        if service.errors?
          render json: service.errors.to_json, status: :unprocessable_entity
        else
          render json: { status: service.project_task.state }
        end
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
