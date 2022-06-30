# == Schema Information
#
# Table name: roles
#
#  id          :uuid             not null, primary key
#  description :text
#  name        :string
#  slug        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Role < ApplicationRecord
  HIERARCHY = [:admin, :executive, :user]

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
    slug == 'admin'
  end

  
end
