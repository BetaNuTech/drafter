function disable_turbo_forms() {
  document.querySelectorAll('form').forEach(function (el) {
    el.dataset.turbo = false
    console.log('DEBUG: turbo forms disabled')
  })
}

document.addEventListener("turbo:load", function() {
  disable_turbo_forms();
});
