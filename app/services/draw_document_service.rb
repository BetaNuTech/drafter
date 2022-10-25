class DrawDocumentService
  class PolicyError < StandardError; end

  attr_reader :user, :draw, :draw_document, :project, :organization, :errors

  def initialize(user:, draw:, draw_document: nil)
    @user = user
    @draw = draw
    @errors = []
    @project = @draw.project
    @organization = @draw.organization
    @draw_document = draw_document || DrawDocument.new(draw: @draw, user: @user)
    @policy = DrawDocumentPolicy.new(@user, @draw_document)
  end

  def errors?
    @errors.any?
  end

  def create(params)
    raise PolicyError.new unless @policy.create?

    reset_errors

    @draw_document = DrawDocument.new(sanitize_draw_document_params(params))
    @draw_document.draw = @draw
    @draw_document.user = @user
    if @draw_document.save
      SystemEvent.log(description: "Added #{@draw_document.description} Document for Draw '#{@draw.index}'", event_source: @project, incidental: @current_user, severity: :warn)
      @draw.draw_documents.reload
    else
      @errors = @draw_document.errors.full_messages
    end
      @draw_document
  end

  def remove(document)
    raise PolicyError.new unless @policy.destroy?

    @draw_document.destroy
      SystemEvent.log(description: "Added Document for Draw '#{@draw.index}'", event_source: @project, incidental: @current_user, severity: :warn)
    @draw.draw_documents.reload
    true
  end

  private

  def reset_errors
    @errors = []
  end

  def sanitize_draw_document_params(params)
    allowed_params = @draw_document_policy.allowed_params
    if params.is_a?(ActionController::Parameters)
      params.permit(*allowed_params)
    else
      params.select{|k,v| allowed_params.include?(k.to_sym) }
    end
  end
  
end
