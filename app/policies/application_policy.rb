class ApplicationPolicy

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end
  end

  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def is_owner?
    record&.user == user
  end

  def privileged_user?
    user.admin? || user.executive?
  end

  def project
    record&.project
  end
end
