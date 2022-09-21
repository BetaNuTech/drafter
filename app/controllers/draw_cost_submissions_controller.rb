class DrawCostSubmissionsController < ApplicationController
  before_action :authenticate_user
  before_action :set_draw, only: %[new create]
  after_action :verify_authorized

  def index
    # TODO
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

  def set_draw
    @draw = DrawPolicy::Scope.new(@current_user, Draw).resolve.
      find(params[:draw_id])
  end

  def record_scope
    # TODO
  end
end
