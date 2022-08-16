# == Schema Information
#
# Table name: project_roles
#
#  id          :uuid             not null, primary key
#  description :text
#  name        :string           not null
#  slug        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_project_roles_on_slug  (slug)
#
class ProjectRole < ApplicationRecord
  OWNER_ROLE = :owner
  MANAGER_ROLE = :manager
  FINANCE_ROLE = :finance
  CONSULTANT_ROLE = :consultant
  DEVELOPER_ROLE = :developer
  HIERARCHY = [OWNER_ROLE, MANAGER_ROLE, FINANCE_ROLE, CONSULTANT_ROLE, DEVELOPER_ROLE]
  MANAGER_ROLES = [OWNER_ROLE, MANAGER_ROLE]
  INTERNAL_ROLES = [OWNER_ROLE, MANAGER_ROLE, FINANCE_ROLE]
  EXTERNAL_ROLES = [CONSULTANT_ROLE, DEVELOPER_ROLE]

  include Comparable
  include Seeds::Seedable

  def <=>(other)
    return 1 if other.nil?
    return 1 if HIERARCHY.index(other.slug&.to_sym).nil?
    return -1 if HIERARCHY.index(slug.to_sym).nil?
    return HIERARCHY.index(other.slug.to_sym) <=> HIERARCHY.index(slug.to_sym)
  end

  def self.owner
    ProjectRole.where(slug: OWNER_ROLE).first
  end

  def self.manager
    ProjectRole.where(slug: MANAGER_ROLE).first
  end

  def self.finance
    ProjectRole.where(slug: FINANCE_ROLE).first
  end

  def self.consultant
    ProjectRole.where(slug: CONSULTANT_ROLE).first
  end

  def self.developer
    ProjectRole.where(slug: DEVELOPER_ROLE).first
  end

  def owner?
    slug == OWNER_ROLE.to_s
  end

  def manager?
    slug == MANAGER_ROLE.to_s
  end

  def developer?
    slug == DEVELOPER_ROLE.to_s
  end

  def management?
    MANAGER_ROLES.include?(slug.to_sym)
  end

  def internal?
    INTERNAL_ROLES.include?(slug.to_sym)
  end

  def external?
    EXTERNAL_ROLES.include?(slug.to_sym)
  end

end
