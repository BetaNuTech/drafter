module ImagesHelper

  # See https://icons.getbootstrap.com/ to preview all icons and their respestive names
  # All BootStrap Icon svg assets have been downloaded to app/assets/images/icons
  ICONS = {
    alert: 'exclamation-triangle-fill.svg',
    circle_check: 'check-circle-fill.svg',
    circle_x_image: 'x-circle-fill.svg',
    destroy: 'trash.svg',
    add: 'plus-square.svg',
    edit: 'pencil-square.svg',
    eye: 'eye-fill.svg',
    eye_slash: 'eye-slash-fill.svg',
    home: 'house-fill.svg',
    info: 'info-circle-fill.svg',
    patch_check: 'patch-check-fill.svg',
    square_check: 'check-square-fill.svg',
    square_check_open: 'check-square.svg',
    square_x: 'x-square-fill.svg',
    square_x_open: 'x-square.svg',
    upload: 'cloud-upload-fill.svg',
    uploaded: 'cloud-check-fill.svg',
    warning: 'exclamation-triangle-fill.svg'
  }.freeze

  # Render SVG icon inline: inline_icon(icon: :icon_name, size: 30, fill: :black, opacity: 1.0, html: {id: })
  def inline_icon(**icon_args)
    args = {
        size: 30,
        fill: :black,
        opacity: 1.0
      }.merge(icon_args)
    style = "height: #{args[:size]}px; width: #{args[:size]}px, fill: #{args[:fill]}, opacity: #{args[:opacity]}" 
    if icon_args.dig(:html, :style).present?
      style << "; " + icon_args[:html][:style]
    end
    svg_data = load_icon(args[:icon]).sub('<svg ', "<svg style=\"#{style}\" ").sub('fill="currentColor"',"fill=\"#{args[:fill]}\"")
    base64_data = Base64.encode64(svg_data)
    content_args = args.fetch(:html,{}).merge({ style:, escape: false, src: "data:image/svg+xml;base64, " + base64_data })
    tag.img **content_args
  end

  def load_icon(name)
    File.open("app/assets/images/icons/#{ICONS.fetch(name.to_sym)}", "rb") do |file|
      raw file.read
    end
  end

  def edit_image
    'icons/pencil-square.svg'
  end

  def destroy_image
    'icons/trash.svg'
  end

  def add_image
    'icons/plus-square.svg'
  end

  def alert_image
    'icons/exclamation-triangle-fill.svg'
  end

  def info_image
    'icons/info-circle-fill.svg'
  end

  def home_image
    'icons/house-fill.svg'
  end

  def edit_image
    'icons/pencil-square.svg'
  end

  def circle_check_image
    'icons/check-circle-fill.svg'
  end

  def circle_x_image
    'icons/x-circle-fill.svg'
  end

  def square_check_image
    'icons/check-square-fill.svg'
  end

  def square_check_open_image
    'icons/check-square.svg'
  end

  def square_x_image
    'icons/x-square-fill.svg'
  end

  def square_x_open_image
    'icons/x-square.svg'
  end

  def upload_image
    'icons/cloud-upload-fill.svg'
  end

  def uploaded_image
    'icons/cloud-check-fill'
  end
end
