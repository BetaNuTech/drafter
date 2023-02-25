module Draws
  module StateMachine
    extend ActiveSupport::Concern

    class_methods do
      def state_names
        Draw.aasm.states.map{|s| s.name.to_s}
      end
    end

    included do
      include AASM
      APPROVED_STATES = %i{ internally_approved externally_approved funded }.freeze
      VISIBLE_STATES = %i{ pending submitted internally_approved externally_approved funded rejected }.freeze
      ALLOW_DRAW_COST_CHANGE_STATES = %i{ pending rejected }.freeze
      ALLOW_DOCUMENT_CHANGE_STATES = %i{ pending rejected }.freeze
      ALLOW_DOCUMENT_APPROVALS_STATES = %i{ submitted }.freeze
      ALLOW_INVOICE_APPROVALS_STATES = %i{ submitted }.freeze
      APPROVAL_LEAD_TIME = 7 # days

      attr_reader :state_errors

      scope :visible, -> { where(state: VISIBLE_STATES) }

      aasm column: :state, whiny_transitions: false do
        state :pending
        state :submitted
        state :internally_approved
        state :externally_approved
        state :funded
        state :rejected
        state :withdrawn

        event :submit do
          transitions from: %i{ pending rejected }, to: :submitted,
            guard: Proc.new{ allow_submit? },
            after: Proc.new {|*args| after_submit(*args) }
        end

        event :approve do
          transitions from: %i{ submitted }, to: :internally_approved,
            guard: Proc.new { allow_approval? },
            after: Proc.new {|*args| after_approval(*args) }
        end

        event :approve_internal do
          transitions from: %i{ submitted }, to: :internally_approved,
            guard: Proc.new { allow_approval? },
            after: Proc.new {|*args| after_approval(*args) }
        end

        event :approve_external do
          transitions from: :internally_approved, to: :externally_approved,
            guard: Proc.new { allow_approval? },
            after: Proc.new {|*args| after_approval(*args) }
        end

        event :reject do
          transitions from: %i{ submitted internally_approved externally_approved }, to: :rejected,
            after: Proc.new {|*args| after_reject(*args) }
        end

        event :withdraw do
          transitions from: %i{ pending submitted rejected internally_approved }, to: :withdrawn,
            after: Proc.new {|*args| after_withdraw(*args) }
        end

        event :fund do
          transitions from: :externally_approved, to: :funded,
            after: Proc.new {|*args| after_funding(*args) }
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
          'in_progress' => 'warning',
          'submitted' => 'warning',
          'internally_approved' => 'primary',
          'externally_approved' => 'primary',
          'funded' => 'success',
          'rejected' => 'danger'
        }.fetch(state, 'light')
      end

      def approved?
        APPROVED_STATES.include?(state.to_sym)
      end

      def allow_draw_cost_changes?
        ALLOW_DRAW_COST_CHANGE_STATES.include?(state.to_sym)
      end

      def allow_document_changes?
        ALLOW_DOCUMENT_CHANGE_STATES.include?(state.to_sym)
      end

      def allow_document_approvals?
        ALLOW_DOCUMENT_APPROVALS_STATES.include?(state.to_sym)
      end

      def allow_invoice_approvals?
        ALLOW_INVOICE_APPROVALS_STATES.include?(state.to_sym)
      end

      def submit_draw_costs(user)
        draw_costs.reload
        draw_costs.where(state: %i{pending rejected}).each do |draw_cost|
          if draw_cost.allow_auto_approve?
            draw_cost.trigger_event(event_name: :approve)
          else  
            draw_cost.trigger_event(event_name: :submit, user: user)
          end
        end
      end

      def revert_to_pending_draw_costs
        draw_costs.reload
        draw_costs.where(state: %i{approved}).each do |draw_cost|
          draw_cost.trigger_event(event_name: :revert_to_pending, user: nil)
        end
      end

      def allow_submit?
        @state_errors = []
        @state_errors << 'Not all documents submitted' unless all_documents_submitted?
        @state_errors << 'No visible Draw Costs' unless draw_costs.visible.any?
        unless draw_costs.visible.all?(&:allow_submit?)
          draw_costs.visible.select{|dc| !dc.allow_submit?}.each do |draw_cost|
            @state_errors << "DrawCost[%{draw_cost}] can't be submitted: %{errors}" % {
              draw_cost: draw_cost.name,
              errors: draw_cost.state_errors.join(', ')
            }
          end
        end

        @state_errors.empty?
      end

      def create_document_approve_tasks
        draw_documents.pending.each do |doc|
          doc.create_task(assignee: nil, action: :approve) rescue false
        end
      end

      def create_draw_approval_tasks
        create_task(action: :approve)
      end

      def after_submit(user)
        submit_draw_costs(user)
        create_document_approve_tasks
      end

      def after_reject(user)
        revert_to_pending_draw_costs
        bubble_event_to_project_tasks(:reject)
        send_state_notification(aasm.to_state)
      end

      def allow_approval?
        all_draw_costs_approved? && all_required_documents_approved?
      end

      def after_approval(user)
        bubble_event_to_project_tasks(:approve)
        approve(user)
        send_state_notification
      end

      def after_withdraw(user=nil)
        items = draw_documents.to_a + invoices.to_a + [self]
        ProjectTask.where(origin: items).each{ |task| task.trigger_event(event_name: :archive, user: user) }
        project_tasks.each{|task| task.trigger_event(event_name: :archive, user: user) }
      end

      def after_funding(user=nil)
        send_state_notification
      end

      def approval_lead_time
        APPROVAL_LEAD_TIME
      end

      def undo_submit
        self.state = 'pending'
        self.save
        draw_documents.update_all(state: :pending)
        draw_costs.each do |dc|
          dc.invoices.each{|i| i.ocr_data = nil; i.annotated_preview = nil; i.state = 'pending'; i.save!}
          dc.state = 'pending'
          dc.save
        end
        reload
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
