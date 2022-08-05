class HomePolicy
  attr_reader :user

  def initialize(user, _record)
    @user = user
  end

  def index?
    true
  end

  def about?
    true
  end
end
