class NotificationMailer < ApplicationMailer
  helper :application

  def draw_status_notification
    @draw = params[:draw]
    @project = @draw.project
    @developers = @project.developers
    owners = @project.owners
    @emails = [@developers, @owners].flatten.map(&:email).compact.uniq

    subject_data = { project: @project.name, draw: @draw.name, state: @draw.state.capitalize }
    subject = "Drafter Notification: %{project} %{draw} is now %{state}" % subject_data

    mail(bcc: @emails, subject:)
  end

  
end
