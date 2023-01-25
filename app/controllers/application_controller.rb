class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include ApplicationHelper

  protect_from_forgery with: :exception
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  around_action :user_timezone, if: :current_user

  def breadcrumbs
    @breadcrumbs ||= Breadcrumbs.new
  end

  def authenticate_service_token
    service = ( params[:service] || '' ).to_sym
    token = params[:token] || ''

    api_token = Rails.application.credentials.dig(service, application_env, :drafter_token)
    if api_token.present? && token == api_token
      return true
    else
      render json: { status: 'Token authentication failed' }, status: :unauthorized
    end
  end

  private

  def application_env
    @application_env ||=
      begin
        if Rails.env.development?
          :development
        elsif Rails.env.test?
          :test
        else
          ( ENV.fetch('APPLICATION_ENV','production') == 'production' ) ? :production : :staging
        end
      end
  end

  def user_timezone(&block)
    Time.use_zone(current_user.timezone, &block)
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to access this page or resource"
    redirect_to(request.referrer || root_url)
  end
end
