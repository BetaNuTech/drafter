import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const el = this.element
    console.log(`DEBUG: Home handler loaded for #${el.id}`)
  }

  say_hello() {
    alert('Hello from Home!')
  }
}
