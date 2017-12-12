module ApplicationHelper
  def short_date(datetime)
    datetime.present? ? datetime.strftime('%m-%d') : nil
  end

  def glyph(type)
    glyph_mappings = {
      create: ['Create', 'glyphicon glyphicon-plus'],
      edit: ['Edit', 'glyphicon glyphicon-pencil'],
      show: ['Show', 'glyphicon glyphicon-eye-open'],
      delete: ['Delete', 'glyphicon glyphicon-trash'],
      back: ['Back', 'glyphicon glyphicon-arrow-left']
    }
    text, glyph_class = glyph_mappings.fetch(type)
    content_tag(:span, '', {class: glyph_class, "aria-hidden": true})
  end

  def nav_active_class(path)
    request.path.match(path) ? 'btn-success btn-nav-active' : 'btn-info'
  end

  def nav_active_dropdown_class(path)
    request.path.match(path) ? 'btn-success' : 'btn-info'
  end
end
