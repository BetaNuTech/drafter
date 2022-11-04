class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def method_missing(m, *args, &block)
    case m
    when :name
      return_default_name
    else
      super
    end
  end

  def return_default_name
    self.class.name
  end

end
