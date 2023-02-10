module ProjectTasks
  module StateMachine
    extend ActiveSupport::Concern

    PENDING_STATES = %w{new needs_review needs_consult rejected}

    class_methods do
      def state_names
        ProjectTask.aasm.states.map{|s| s.name.to_s}
      end
    end

    included do
      include AASM

      scope :pending, -> { where(state: ProjectTasks::StateMachine::PENDING_STATES) }

      aasm column: :state do
        state :new
        state :needs_review
        state :needs_consult
        state :rejected
        state :approved
        state :archived

        event :submit_for_review do
          transitions from: %i{new archived}, to: :needs_review,
            after: Proc.new{|*args| after_submit(*args)}
        end

        event :submit_for_consult do
          transitions from: %i{new needs_review archived}, to: :needs_consult,
            after: Proc.new{|*args| after_submit(*args)}
        end

        event :approve do
          transitions from: %i{new needs_review needs_consult rejected archived}, to: :approved,
            after: Proc.new{|*args| after_approve(*args)}
        end

        event :reject do
          transitions from: %i{new needs_review needs_consult approved archived}, to: :rejected,
            after: Proc.new{|*args| after_reject(*args)}
        end

        event :archive do
          transitions from: %i{new needs_review needs_consult approved rejected}, to: :archived,
            after: Proc.new{|*args| after_archive(*args)}
        end
      end

      def trigger_event(event_name:, user: nil)
        event = event_name.to_sym
        if permitted_state_events.include?(event)
          self.aasm.fire!(event, user)
          return self.save
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

      def pending?
        PENDING_STATES.include?(state)
      end

      def due?
        pending? && Time.current >= due_at
      end

      def after_submit(user)
        self.remoteid = nil
        save
        delay.create_remote_task
        true
      end

      def after_approve(user)
        delay.approve_remote_task
        true
      end

      def after_reject(user)
        delay.reject_remote_task
        true
      end

      def after_archive(user)
        delay.archive_remote_task
        true
      end

    end
  end
end
