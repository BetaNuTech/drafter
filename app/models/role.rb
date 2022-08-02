# == Schema Information
#
# Table name: roles
#
#  id          :uuid             not null, primary key
#  description :text
#  name        :string           not null
#  slug        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_roles_on_slug  (slug) UNIQUE
#
class Role < ApplicationRecord
  ADMIN_ROLE = :admin
  EXECUTIVE_ROLE = :executive
  USER_ROLE = :user
  HIERARCHY = [ ADMIN_ROLE, EXECUTIVE_ROLE, USER_ROLE].freeze

  include Comparable
  include Seeds::Seedable

  has_many :users
  #validates uniqueness: :slug

  def self.admin
    Role.where(slug: :admin).first
  end

  def self.executive
    Role.where(slug: :executive).first
  end

  def self.user
    Role.where(slug: :user).first
  end

  def <=>(other)
    return 1 if other.nil?
    return 1 if HIERARCHY.index(other.slug&.to_sym).nil?
    return -1 if HIERARCHY.index(slug.to_sym).nil?
    return HIERARCHY.index(other.slug.to_sym) <=> HIERARCHY.index(slug.to_sym)
  end

  def admin?
    slug == ADMIN_ROLE.to_s
  end

  def executive?
    slug == EXECUTIVE_ROLE.to_s
  end

  def user?
    slug == USER_ROLE.to_s
  end

  
end
