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
    @draw_document_policy = DrawDocumentPolicy.new(@user, @draw_document)
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
