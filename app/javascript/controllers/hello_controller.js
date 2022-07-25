import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.textContent = "Hello World!"
    say_hello()
  }

  say_hello() {
    console.log('Hello world!')
  }
}