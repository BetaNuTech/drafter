class NotificationMailer < ApplicationMailer
  helper :application

  def draw_status_notification
    @draw = params[:draw]
    @new_state = params[:new_state] || @draw.state
    @project = @draw.project
    @developers = @project.developers
    @owners = @project.owners
    @emails = [@developers, @owners].flatten.map(&:email).compact.uniq

    @email_data = { project: @project.name,
                    draw: @draw.name,
                    draw_full_name: "%{project} %{draw}" % { project: @project.name, draw: @draw.name},
                    state: @new_state.capitalize
                  }
    subject = "Drafter Notification: %{draw_full_name} is now %{state}" % @email_data

    mail(bcc: @emails, subject:)
  end

  
end
