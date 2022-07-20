module Projects
  class Updater
    attr_reader :project, :user

    def initialize(project, current_user: )
      @project = project
      @current_user = user
      @policy = ProjectPolicy.new(@project, @current_user)
      @errors = []
    end

    def create(params)
      if @project.id.present?
        return update(params)
      end

      @project = Project.new(sanitize_params(params))
      if @project.save
        SystemEvent.log(description: 'Created new project',event_source: @project, incidental: @current_user, severity: :warn)
        return @project
      else
        record_errors
        return false
      end
    end

    def update(params)
      if @project.update(sanitize_params(params))
        SystemEvent.log(description: 'Updated project',event_source: @project, incidental: @current_user, severity: :info)
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

      if users.include?(user)
        return user
      end

      project_role = ProjectRole.where(slug: role).first
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
        return user
      else
        msg = "Could not add member: #{project_user.full_messages.join(', ')}"
        @errors << msg
        return nil
      end
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

      user
    end

    def errors?
      @errors.present?
    end

    private

    def member_management_check!

    end

    def refresh_policy
      @policy = ProjectPolicy.new(@project, @current_user)
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
