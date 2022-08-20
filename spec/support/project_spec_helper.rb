module ProjectSpecHelper
  def add_project_user(user:, project:, role:)
    project.add_user(user: user, role: role)
    project.reload
    user.reload
    user
  end
end
