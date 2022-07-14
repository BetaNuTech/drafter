class ApplicationMailer < ActionMailer::Base
  default from: MAILER_FROM
  layout "mailer"
end
