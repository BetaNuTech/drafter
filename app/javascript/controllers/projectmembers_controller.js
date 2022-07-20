import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const el = this.element
    console.log(`DEBUG: Project Members controller loaded for #${el.id}`)
  }

  add_member(e) {
    e.preventDefault()
    console.log('DEBUG: clicked "Add Member"')

    
  }

}
