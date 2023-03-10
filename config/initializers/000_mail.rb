if Rails.env.production?
  ActionMailer::Base.delivery_method = :smtp
  if PRODUCTION_MODE
    # PRODUCTION ActionMailer config
    MAILER_FROM = Rails.application.credentials.mail.production.from_address.freeze
    provider = Rails.application.credentials.mail.production.provider
    case provider
      when 'sendgrid'
        ActionMailer::Base.smtp_settings = {
          :port           => Rails.application.credentials.mail.production.sendgrid.smtp_port,
          :address        => Rails.application.credentials.mail.production.sendgrid.smtp_address,
          :user_name      => Rails.application.credentials.mail.production.sendgrid.smtp_username,
          :password       => Rails.application.credentials.mail.production.sendgrid.smtp_password,
          :domain         => Rails.application.credentials.mail.production.sendgrid.smtp_domain,
          :authentication => Rails.application.credentials.mail.production.sendgrid.smtp_authentication,
          :enable_starttls_auto => Rails.application.credentials.mail.production.sendgrid.smtp_enable_starttls_auto
        }
      when 'cloudmailin'
        ActionMailer::Base.smtp_settings = {
          :port           => Rails.application.credentials.mail.production.cloudmailin.smtp_port,
          :address        => Rails.application.credentials.mail.production.cloudmailin.smtp_address,
          :user_name      => Rails.application.credentials.mail.production.cloudmailin.smtp_username,
          :password       => Rails.application.credentials.mail.production.cloudmailin.smtp_password,
          :domain         => Rails.application.credentials.mail.production.cloudmailin.smtp_domain,
          :authentication => Rails.application.credentials.mail.production.cloudmailin.smtp_authentication,
          :enable_starttls_auto => Rails.application.credentials.mail.production.cloudmailin.smtp_enable_starttls_auto
        }
    end
  else
    # STAGING ActionMailer config
    MAILER_FROM = Rails.application.credentials.mail.staging.from_address.freeze
    provider = Rails.application.credentials.mail.staging.provider
    case provider
      when 'sendgrid'
        ActionMailer::Base.smtp_settings = {
          :port           => Rails.application.credentials.mail.staging.sendgrid.smtp_port,
          :address        => Rails.application.credentials.mail.staging.sendgrid.smtp_address,
          :user_name      => Rails.application.credentials.mail.staging.sendgrid.smtp_username,
          :password       => Rails.application.credentials.mail.staging.sendgrid.smtp_password,
          :domain         => Rails.application.credentials.mail.staging.sendgrid.smtp_domain,
          :authentication => Rails.application.credentials.mail.staging.sendgrid.smtp_authentication,
          :enable_starttls_auto => Rails.application.credentials.mail.staging.sendgrid.smtp_enable_starttls_auto
        }
      when 'cloudmailin'
        # NOT USED/CONFIGURED
    end
  end
end

if Rails.env.development?
  ActionMailer::Base.delivery_method = :letter_opener_web
  MAILER_FROM = 'drafter.dev@localhost'.freeze
end

if Rails.env.test?
  MAILER_FROM = 'drafter.test@localhost'.freeze
end
