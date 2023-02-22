import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    var container = this.element

    var description_button = container.querySelector(".eye_icon_description_popover")
    this.init_description_popover(description_button)

    var description_button_2 = container.querySelector(".eye_slash_icon_description_popover")
    this.init_description_popover(description_button_2)

    var description_button_3 = container.querySelector(".invoice_description_popover")
    this.init_description_popover(description_button_3)
  }

  init_description_popover(el) {
    try {
      var popover = new bootstrap.Popover(el)
    } catch {
      console.log('skipping popover',el.id, 'with no content')
      return(true)
    }
  }
}
