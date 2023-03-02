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

    var description_button_4 = container.querySelector(".ocr_matched_icon_description_popover")
    this.init_description_popover(description_button_4)

    var description_button_5 = container.querySelector(".ocr_no_match_icon_description_popover")
    this.init_description_popover(description_button_5)

    var description_button_6 = container.querySelector(".ocr_failed_icon_description_popover")
    this.init_description_popover(description_button_6)

    var description_button_7 = container.querySelector(".draw_document_description_popover")
    this.init_description_popover(description_button_7)

    var description_button_8 = container.querySelector(".patch_check_icon_description_popover")
    this.init_description_popover(description_button_8)
  }

  init_description_popover(el) {
    try {
      var popover = new bootstrap.Popover(el)
    } catch {
      if (el !== null) {
        console.log('skipping popover for',el.id, 'with no content')
      }
      return(true)
    }
  }
}
