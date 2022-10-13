module Projects
  class Updater
    attr_reader :project, :current_user

    def initialize(current_user, project)
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
        add_project_costs(@project)
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

    def available_members
      @project.available_users
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

    def add_project_costs(project)
      ProjectCostSample.standard.order(cost_type: :asc, name: :asc).each do |sample|
        project.project_costs.create(
          cost_type: sample.cost_type,
          name: sample.name,
          approval_lead_time: sample.approval_lead_time,
          total: 0.0,
          state: 'pending'
        )
      end
      @project.project_costs.reload
    end

    def refresh_policy
      @policy = ProjectPolicy.new(@current_user, @project)
    end

    def record_errors
      @errors = []
      @project.errors.full_messages.each do |error|
        @errors << error
      end
      @errors
    end

    def sanitize_params(params)
      allowed_params = @policy.allowed_params
      if params.is_a?(ActionController::Parameters)
        params.require(:project).permit(*allowed_params)
      else
        params.select{|k,v| allowed_params.include?(k.to_s) }
      end
    end

  end
end
