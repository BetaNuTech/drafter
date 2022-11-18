function format_input_as_currency(element) {
  let value = element.valueAsNumber
  value = isNaN(value) ? 0.0 : value
  let formatted_value = parseFloat(value).toFixed(2)
  element.value = formatted_value
}

function format_currency_handler() {
  const elements = document.getElementsByClassName('currency_input')
  Array.prototype.forEach.call(elements, (element) => {
    if ('number' != element.type) { return(true) }

    format_input_as_currency(element)
    element.addEventListener('change', (event) => { format_input_as_currency(event.target) })
  })
} 

window.addEventListener('load', format_currency_handler)
document.documentElement.addEventListener('turbo:frame-load', format_currency_handler)
