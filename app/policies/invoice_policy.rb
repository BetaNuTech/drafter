class InvoicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      case user
      when -> (u) { u.admin? }
        scope
      when -> (u) { u.executive? }
        scope
      else
        scope.includes(draw_cost: [:draw]).where(
          draws: { project: u.projects, organization_id: u.organization_id }
        )
      end
    end
  end
end
