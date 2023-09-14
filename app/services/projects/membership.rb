module Projects
  class Membership
    attr_reader :project, :user, :project_user, :policy

    def initialize(current_user:, project:)
      @project = project
      @current_user = current_user
      @policy = ProjectPolicy.new(@current_user, @project)
      @errors = []
    end

    def project_user
      ProjectUser.new(project: @project)
    end

    def memberships
      @project.project_users
    end

    def members
      @project.users.includes(user: :profile).order("user_profiles.last_name ASC, user_profiles.first_name ASC")
    end

    def add_member(user: , role: )
      unless @policy.add_member?
        msg = "You don't have permission to add members to this project"
        @errors << msg
        return nil
      end

      user = User.active.where(id: user).first if user.is_a?(String)
      if @project.users.include?(user)
        return project_user
      end

      project_role = role.is_a?(ProjectRole) ? role : ProjectRole.where(id: role).first
      unless project_role.present?
        msg = "Invalid project role '#{role}'"
        @errors << msg
        return nil
      end

      project_user = ProjectUser.new(project: @project, user: user, project_role: project_role)
      if project_user.save
        msg = "Added #{user.name} with the #{project_role.name} role"
        @project.project_users.reload
        SystemEvent.log(description: msg, event_source: @project, incidental: user, severity: :warn)
        user.projects.reload
        project.users.reload
        if project_role.external?
          notify_owners_of_membership(@project, user, project_role)
        end
        return project_user
      else
        msg = "Could not add member: #{project_user.full_messages.join(', ')}"
        @errors << msg
        return nil
      end
    end

    def notify_owners_of_membership(project, user, project_role)
      mailer = NotificationMailer.with(project: project, user: user, project_role: project_role).project_role_notification
  
      if Rails.env.test?
        mailer.deliver
      else
        mailer.deliver_later
      end
    end

    def notify_member_of_role_change(project_user)
      # TODO create notification record for user
      # TODO create Project mailer
      # TODO create Project mailer action
      # TODO send notification email
    end

    def update_member_role(user:, role: )
      unless @policy.add_member?
        msg = "You don't have permission to update members in this project"
        @errors << msg
        return nil
      end

      project_user = @project.project_users.where(user_id: user.id).first
      unless project_user.present?
        msg = "Could not find project member"
        @errors << msg
        return nil
      end

      project_role = ProjectRole.where(id: role).first
      unless project_role.present?
        msg = "Invalid project role '#{role}'"
        @errors << msg
        return project_user
      end

      project_user.project_role = project_role
      unless project_user.save
        msg = "Could not assign member role"
        @errors << msg
        return project_user
      end
      msg = "#{user.name} was re-assigned to the #{project_role.name} role"
      SystemEvent.log(description: msg, event_source: @project, incidental: project_user.user, severity: :info)
      if project_role.external?
        notify_owners_of_membership(@project, user, project_role)
      end
      project_user
    end

    def remove_member(user)
      project_user = @project.project_users.where(user_id: user.id).first
      unless project_user.present?
        msg = "Could not find project member"
        @errors << msg
        return nil
      end

      project_user.destroy
      log_message = "Removed %s as a member" % [project_user.name]
      SystemEvent.log(description: log_message, event_source: @project, incidental: project_user.user, severity: :info)

      @project.reload
      return true
    end

    def available_members
      @project.available_users
    end

    def member_count
      @project.users.count
    end

    def available_roles
      ProjectRole.in_order_of(:slug, ProjectRole::HIERARCHY)
    end
    
  end
end
