module ChangeOrders
  module StateMachine
    extend ActiveSupport::Concern

    class_methods do
      def state_names
        ChangeOrder.aasm.states.map{|s| s.name.to_s}
      end
    end

    included do
      class TransitionError < StandardError; end;

      VISIBLE_STATES = %i{pending submitted approved rejected}

      scope :visible, -> { where(state: VISIBLE_STATES) }

      include AASM

      aasm column: :state, whiny_transitions: false do
        state :pending
        state :approved
        state :rejected
        state :withdrawn

        ### Callbacks

        event :approve, after_commit: :after_approve do
          transitions from: %i{ pending rejected }, to: :approved,
            guard: Proc.new { allow_approve? }
        end

        event :reject, after_commit: :after_reject do
          transitions from: %i{ pending approved }, to: :rejected,
            guard: Proc.new { allow_reject? }
        end

        event :reset_approval, after_commit: :after_reset_approval do
          transitions from: %i{ approved rejected }, to: :pending,
            guard: Proc.new { allow_approve? }
        end

        event :withdraw, after_commit: :after_withdraw do
          transitions from: %i{ pending approved rejected }, to: :withdrawn
        end
      end

      def after_approve(user)
        draw_cost.after_last_change_order_approval
        bubble_event_to_project_tasks(:approve)
      end

      def after_reject(user)
        bubble_event_to_project_tasks(:reject)
        draw_cost.trigger_event(event_name: :reject, user: user)
      end

      def after_reset_approval(user)
        # Reset Draw Cost to pending state
        if draw_cost.approved?
          draw_cost.trigger_event(event_name: :revert_to_pending, user: user) if
            draw_cost.permitted_state_events.include?(:revert_to_pending)
        end

        # Clear pending tasks and create a new approve task
        project_tasks.pending.each{|task| task.trigger_event(event_name: :archive, user: user)}
        create_task(action: :approve)
      end

      def after_withdraw(user)
        archive_project_tasks
      end

      def allow_approve?
        draw_cost.draw.allow_invoice_approvals?
      end

      def allow_reject?
        draw_cost.draw.allow_invoice_approvals?
      end

      def allow_reset_approval?
        draw_cost.draw.allow_invoice_approvals?
      end

      def bubble_event_to_project_tasks(event_name)
        task_event = case event_name.to_sym
                     when :approve, :reject
                       event_name.to_sym
                     end
        project_tasks.pending.each do |task|
          task.trigger_event(event_name: task_event) if task.permitted_state_events.include?(task_event)
        end
      end

      def displayed_state_name
        state
      end

      def archive_project_tasks(recurse: false)
        project_tasks.each{|task| task.trigger_event(event_name: :archive)}
      end

      def state_css_class
        {
          'pending' => 'secondary',
          'submitted' => 'warning',
          'approved' => 'success',
          'rejected' => 'danger',
        }.fetch(state, 'primary')
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
    end

  end
end
