import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['project_cost_select', 'total_input', 'save_button']
  connect() {
    console.log('-- Draw Cost Form initialized --')
  }
}
