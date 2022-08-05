if Rails.env.production?
  ActionMailer::Base.delivery_method = :smtp
  if ENV.fetch('APPLICATION_ENV','production') == 'production'
    ActionMailer::Base.smtp_settings = {
      :port           => Rails.application.credentials.sendgrid.smtp_port,
      :address        => Rails.application.credentials.sendgrid.smtp_address,
      :user_name      => Rails.application.credentials.sendgrid.smtp_username,
      :password       => Rails.application.credentials.sendgrid.smtp_password,
      :domain         => Rails.application.credentials.sendgrid.smtp_domain,
      :authentication => Rails.application.credentials.sendgrid.smtp_authentication,
      :enable_starttls_auto => Rails.application.credentials.sendgrid.smtp_enable_starttls_auto
    }
    MAILER_FROM = Rails.application.credentials.from_address.freeze
  else
    ActionMailer::Base.smtp_settings = {
      :port           => Rails.application.credentials.staging_sendgrid.smtp_port,
      :address        => Rails.application.credentials.staging_sendgrid.smtp_address,
      :user_name      => Rails.application.credentials.staging_sendgrid.smtp_username,
      :password       => Rails.application.credentials.staging_sendgrid.smtp_password,
      :domain         => Rails.application.credentials.staging_sendgrid.smtp_domain,
      :authentication => Rails.application.credentials.staging_sendgrid.smtp_authentication,
      :enable_starttls_auto => Rails.application.credentials.staging_sendgrid.smtp_enable_starttls_auto
    }
    MAILER_FROM = Rails.application.credentials.staging_from_address.freeze
  end
end

if Rails.env.development?
  ActionMailer::Base.delivery_method = :letter_opener_web
  MAILER_FROM = 'developer@localhost'.freeze
end
