class DrawDocumentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_draw
  before_action :set_draw_document, except: %i[index new create]
  after_action :verify_authorized

  def new
    @draw_document = DrawDocument.new(draw: @draw, user: @current_user)
    authorize @draw_document
  end

  # TODO
  def create
    @draw_document = DrawDocument.new(draw: @draw, user: @current_user)
    authorize @draw_document
    @service = DrawDocumentService.new(draw: @draw, user: @current_user)
    @draw_document = @service.create(params)
    respond_to do |format|
      if @service.errors?
    
      else
      end
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

  def set_draw_document
    @draw_document = record_scope.find(params[:id] || params[:draw_document_id])
  end

end
