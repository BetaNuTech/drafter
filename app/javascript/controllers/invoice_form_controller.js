import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["file_field", "file_selected_image", "submit_button", "file_upload_prompt", "amount_field"]

  file_changed(){
    const upload_image_el = this.file_upload_promptTarget
    const selected_image_el = this.file_selected_imageTarget
    const submit_button_el = this.submit_buttonTarget
    if (this.file_present()) {
      upload_image_el.classList.add('d-none')
      selected_image_el.classList.remove('d-none')
      if (this.valid_amount()) {
        submit_button_el.removeAttribute('disabled')
      }
    }
  }

  amount_changed() {
    const submit_button_el = this.submit_buttonTarget
    if (this.file_present() && this.valid_amount()) {
      submit_button_el.removeAttribute('disabled')
    }
  }

  file_present() {
    const file_field_el = this.file_fieldTarget 
    const filename = file_field_el.value
    return(filename.length > 10)
  }

  valid_amount() {
    const amount_field_el = this.amount_fieldTarget
    const amount = amount_field_el.value
    return(amount > 0.0)
  }

 } 
