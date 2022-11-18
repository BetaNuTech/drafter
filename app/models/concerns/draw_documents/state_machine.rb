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
      aasm column: :state do
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
          transitions from: %i{pending approved rejected}, to: :withdrawn
        end
      end

      def trigger_event(event_name:, user: nil)
        event = event_name.to_sym
        if permitted_state_events.include?(event)
          self.aasm.fire(event, user)
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
        mark_approval_by(user) 
      end

      def after_reject(user)
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
      end
    end

  end
end
