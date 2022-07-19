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
  HIERARCHY = [:owner, :manager, :finance, :consultant, :developer]

  include Comparable
  include Seeds::Seedable

  def <=>(other)
    return 1 if other.nil?
    return 1 if HIERARCHY.index(other.slug&.to_sym).nil?
    return -1 if HIERARCHY.index(slug.to_sym).nil?
    return HIERARCHY.index(other.slug.to_sym) <=> HIERARCHY.index(slug.to_sym)
  end
end
