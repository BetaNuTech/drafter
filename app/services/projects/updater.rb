module Projects
  class Updater
    attr_reader :project, :current_user

    def initialize(project, current_user)
      @project = project
      @current_user = current_user
      @policy = ProjectPolicy.new(@current_user, @project)
      @errors = []
    end

    def create(params)
      if @project.id.present?
        return update(params)
      end

      @project = Project.new(sanitize_params(params))
      if @project.save
        SystemEvent.log(description: 'Created new project', event_source: @project, incidental: @current_user, severity: :warn)
        return @project
      else
        record_errors
        return false
      end
    end

    def update(params)
      if @project.update(sanitize_params(params))
        SystemEvent.log(description: 'Updated project', event_source: @project, incidental: @current_user, severity: :info)
        return @project
      else
        record_errors
        return false
      end
    end
    
    def add_member(user: , role: )
      unless @policy.add_member?
        msg = "You don't have permission to add members to this project"
        @errors << msg
        return nil
      end

      user = User.active.where(id: user).first unless user.is_a?(User)
      if users.include?(user)
        return user
      end

      project_role = role.is_a?(ProjectRole) ? role : ProjectRole.where(id: role).first
      unless project_role.present?
        msg = "Invalid project role '#{role}'"
        @errors << msg
        return nil
      end

      project_user = ProjectUser.new(project: @project, user: user, role: project_role)
      if project_user.save
        msg = "Added #{user.name} as a #{project_role.name}"
        @project.project_users.reload
        SystemEvent.log(description: msg, event_source: @project, incidental: user, severity: :warn)
        user.projects.reload
        project.users.reload
        notify_member_of_role_change
        return user
      else
        msg = "Could not add member: #{project_user.full_messages.join(', ')}"
        @errors << msg
        return nil
      end
    end

    def notify_member_of_role_change
      # TODO create event record
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

      project_user = @project.project_users.where(user_id: user.id)
      unless project_user.present?
        msg = "Could not find project member"
        @errors << msg
        return nil
      end

      project_role = ProjectRole.where(slug: role).first
      unless project_role.present?
        msg = "Invalid project role '#{role}'"
        @errors << msg
        return user
      end

      project_user.role = project_role
      unless project_user.save
        msg = "Could not assign member role"
        @errors << msg
        return user
      end
      notify_member_of_role_change
      user
    end

    def available_members
      current_members = @project.users.pluck(&:id)
      User.active.where.not(id: current_members).ordered_by_name
    end

    def member_count
      @project.users.count
    end

    def available_roles
      ProjectRole.in_order_of(:slug, ProjectRole::HIERARCHY)
    end

    def errors?
      @errors.present?
    end

    private

    def member_management_check!

    end

    def refresh_policy
      @policy = ProjectPolicy.new(@current_user, @project)
    end

    def record_errors
      @errors = []
      @project.full_messages.each do |error|
        @errors << error
      end
      @errors
    end

    def sanitize_params(params)
      allowed_params = @policy.allowed_params
      if params.is_a?(ActionController::Parameters)
        params.require(:project).permit(*allowed_params)
      else
        params.select{|k,v| allow_params.include?(k.to_s) }
      end
    end

  end
end
