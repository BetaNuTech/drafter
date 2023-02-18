module DrawDocuments
  module StateMachine
    extend ActiveSupport::Concern

    class_methods do
      def state_names
        DrawDocument.aasm.states.map{|s| s.name.to_s}
      end
    end

    included do
      VISIBLE_STATES = %i{pending approved rejected}.freeze

      scope :visible, -> { where(state: VISIBLE_STATES) }

      include AASM
      aasm column: :state, whiny_transitions: false do
        state :pending
        state :approved
        state :rejected
        state :withdrawn

        event :approve do
          transitions from: %i{ pending rejected }, to: :approved, 
            guard: Proc.new { allow_approve? },
            after: Proc.new {|*args| after_approve(*args) }
        end

        event :reject do
          transitions from: %i{ pending approved }, to: :rejected,
            guard: Proc.new { allow_reject? },
            after: Proc.new {|*args| after_reject(*args) }
        end

        event :reset_approval do
          transitions from: %i{approved rejected}, to: :pending,
            after: Proc.new{|*args| after_reset_approval(*args)}
        end

        event :withdraw do
          transitions from: %i{pending approved rejected}, to: :withdrawn,
            after: Proc.new{|*args| after_withdraw(*args)}
        end
      end

      def trigger_event(event_name:, user: nil)
        event = event_name.to_sym
        if permitted_state_events.include?(event)
          return ( self.aasm.fire!(event, user) && self.save )
        else
          return false
        end
      end

      def permitted_state_events
        aasm.events(permitted: true).map(&:name)
      end

      def permitted_states
        aasm.states(permitted: true).map(&:name)
      end

      def state_css_class
        {
          'pending' => 'info',
          'submitted' => 'warning',
          'approved' => 'success',
          'rejected' => 'danger',
          'withdrawn' => 'secondary'
        }.fetch(state, 'light')
      end

      def after_approve(user)
        bubble_event_to_project_tasks(:approve)
        mark_approval_by(user) 
      end

      def after_reject(user)
        bubble_event_to_project_tasks(:reject)
        unapprove
      end

      def allow_reject?
        draw.allow_document_approvals?
      end

      def allow_approve?
        draw.allow_document_approvals?
      end

      def after_reset_approval(user)
        unapprove 

        # Clear pending tasks and create a new Approve task
        project_tasks.each{|task| task.trigger_event(event_name: :archive, user: user)}
        create_task(assignee: nil, action: :approve)
      end

      def after_withdraw(user=nil)
        project_tasks.each{|task| task.trigger_event(event_name: :archive, user: user)}
      end

      def bubble_event_to_project_tasks(event_name)
        task_event = case event_name.to_sym
                     when :approve, :reject
                       event_name.to_sym
                     when :withdraw
                       :archive
                     end
        project_tasks.pending.each do |task|
          task.trigger_event(event_name: task_event) if task.permitted_state_events.include?(task_event)
        end
      end
    end

  end
end
