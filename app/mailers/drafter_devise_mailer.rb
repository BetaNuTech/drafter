class DrafterDeviseMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  default template_path: 'devise/mailer' # to make sure that you mailer uses the devise views

  def confirmation_instructions(record, token, opts={})
    opts[:subject] = "Welcome to Drafter! Please confirm your account."
    @name = record.name
    super
  end

end