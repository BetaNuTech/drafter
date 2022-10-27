class DrawDocumentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_draw
  before_action :set_draw_document, except: %i[index new create]
  after_action :verify_authorized

  def new
    @draw_document = DrawDocument.new(draw: @draw, user: @current_user)
    authorize @draw_document
  end

  def create
    @draw_document = DrawDocument.new(draw: @draw, user: @current_user)
    authorize @draw_document
    @service = DrawDocumentService.new(draw: @draw, user: @current_user)
    @draw_document = @service.create(params[:draw_document])
    respond_to do |format|
      if @service.errors?
        format.html { render :new, status: :unprocessable_entity  }
      else
        @draw.draw_documents.reload
        format.html {
          redirect_to draw_draw_document_path(draw_id: @draw.id, id: @draw_document.id), notice: 'Added Document' }
        format.turbo_stream
      end
    end
  end

  def show
    authorize @draw_document
  end

  def destroy
    authorize @draw_document
    @service = DrawDocumentService.new(draw: @draw, draw_document: @draw_document, user: @current_user)
    @service.remove
    @draw.draw_documents.reload
  end

  private

  def draw_record_scope
    DrawPolicy::Scope.new(@current_user, Draw).resolve
  end

  def record_scope
    @draw.draw_documents
  end

  def set_draw
    @draw = draw_record_scope.find(params[:draw_id])
  end

  def set_draw_document
    @draw_document = record_scope.find(params[:id] || params[:draw_document_id])
  end

end
