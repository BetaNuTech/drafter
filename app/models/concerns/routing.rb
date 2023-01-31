module Routing
  extend ActiveSupport::Concern

  included do
    include Rails.application.routes.url_helpers
  end

  def default_url_options
    Rails.application.config.action_mailer.default_url_options
  end

  def application_protocol
    ENV.fetch('APPLICATION_PROTOCOL', 'http')
  end

  def application_host
    ENV.fetch('APPLICATION_HOST', 'localhost:3000')
  end

  def url_prefix
    "#{application_protocol}://#{application_host}"
  end
end
