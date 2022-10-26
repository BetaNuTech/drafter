import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    let container = this.element
    let description_button = container.querySelector(".invoice_description_popover")
    this.init_description_popover(description_button)
  }

  init_description_popover(el) {
    try {
      var popover = new bootstrap.Popover(el)
    } catch {
      console.log('no popover description')
      return(true)
    }
  }
}
