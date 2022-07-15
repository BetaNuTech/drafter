class OrganizationPolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      scope
      case user
      when -> (u) { u.admin?}
        scope
      when -> (u) { u.executive? }
        scope
      else
        Organization.where("1=1")
      end
    end
  end

  def index?
   return false unless user

   user.admin? || user.executive?
  end

  def new?
    user.admin? || user.executive?
  end

  def create?
    new?
  end

  def edit?
    user.admin? || user.executive?
  end

  def update?
    edit?
  end

  def show?
    index?
  end

  def destroy?
    ( user.admin? || user.executive? ) && record.users.empty?
  end


  def allowed_params
    case user
    when ->(u) { u.admin? }
      Organization::ALLOWED_PARAMS
    when ->(u) { u.corporate? }
      Organization::ALLOWED_PARAMS
    else
      []
    end
  end

  def organizations_for_select
    Scope.new(user, record).resolve.
      order(name: :asc).
      map{|org| [org.name, org.id]}
  end

end
