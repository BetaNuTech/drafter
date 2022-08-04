class Breadcrumbs
  include Enumerable
  BreadCrumb = Struct.new(:label, :url, :active)

  def initialize
    @list = []
  end

  def add(label:, url:, active: false)
    @list << BreadCrumb.new(label, url, active)
  end

  def to_a
    @list
  end

  def each
    @list.each{|i| yield i}
  end
end
