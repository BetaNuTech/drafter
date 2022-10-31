class DrawDocumentService
  class PolicyError < StandardError; end

  attr_reader :user, :draw, :draw_document, :project, :organization, :errors

  def initialize(user:, draw: nil, draw_document: nil)
    raise ActiveRecord::RecordNotFound unless ( draw.present? || draw_document.present? )

    @errors = []
    @user = user
    if draw.present?
      @draw = draw
      @draw_document = draw_document || DrawDocument.new(draw: @draw, user: @user, notes: nil)
    else
      @draw_document = draw_document
      @draw = @draw_document.draw
    end
    @project = @draw.project
    @organization = @draw.organization
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

  def remove
    raise PolicyError.new unless @policy.destroy?

    document_type = @draw_document.documenttype.capitalize
    @draw_document.trigger_event(event_name: :withdraw, user: @user)
    SystemEvent.log(description: "Removed #{@draw_document.description} Document for Draw '#{@draw.index}'", event_source: @project, incidental: @current_user, severity: :warn)
    @draw.draw_documents.reload
    true
  end

  def approve
    raise PolicyError.new unless @policy.approve?

    reset_errors

    if @draw_document.trigger_event(event_name: :approve, user: @user)
      SystemEvent.log(description: "Approved #{@draw_document.description} Document for Draw '#{@draw.index}'", event_source: @project, incidental: @current_user, severity: :warn)
      true
    else
      @errors << 'Could not approve this document'
      false
    end
  end

  def reject
    raise PolicyError.new unless @policy.reject?

    reset_errors

    if @draw_document.trigger_event(event_name: :reject, user: @user)
      SystemEvent.log(description: "Rejected #{@draw_document.description} Document for Draw '#{@draw.index}'", event_source: @project, incidental: @current_user, severity: :warn)
      true
    else
      @errors << 'Could not approve this document'
      false
    end
  end

  private

  def reset_errors
    @errors = []
  end

  def sanitize_draw_document_params(params)
    allowed_params = @policy.allowed_params
    if params.is_a?(ActionController::Parameters)
      params.permit(*allowed_params)
    else
      params.select{|k,v| allowed_params.include?(k.to_sym) }
    end
  end
  
end
