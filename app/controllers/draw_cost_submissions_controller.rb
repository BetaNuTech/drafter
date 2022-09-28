class DrawCostSubmissionsController < ApplicationController
  before_action :authenticate_user
  before_action :set_draw, only: %[new create]
  after_action :verify_authorized

  # GET #index disabled
  def index
    raise ActiveRecord::RecordNotFound
  end

  def new
    # TODO
  end

  def create
    # TODO
  end

  def show
    # TODO
  end

  def edit
    # TODO
  end

  def update
    # TODO
  end

  def destroy
    # TODO
  end

  private
  
  def draw_scope
    DrawPolicy::Scope.new(@current_user, Draw).resolve
  end

  def set_draw
    @draw = draw_scope.find(params[:draw_id])
  end

  def record_scope
    policy_scope(DrawCostSubmission)
  end

  def set_draw_cost_submission
    @draw_cost_submission = record_scope.find(params[:id])
  end
end
