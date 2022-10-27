var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
var popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
  try {
    return new bootstrap.Popover(popoverTriggerEl)
  } catch {
    console.log('skipping', popoverTriggerEl.id, 'with no content')
  }
})
