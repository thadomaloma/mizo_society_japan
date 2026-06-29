import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "input", "form"]

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.handleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
    clearTimeout(this.searchTimer)
  }

  open(event) {
    event?.preventDefault()
    this.modalTarget.classList.remove("hidden")
    this.inputTarget.focus()
  }

  close(event) {
    event?.preventDefault()
    this.modalTarget.classList.add("hidden")
  }

  closeFromBackdrop(event) {
    if (event.target === this.modalTarget) this.close()
  }

  queueSearch() {
    clearTimeout(this.searchTimer)
    this.searchTimer = setTimeout(() => this.formTarget.requestSubmit(), 180)
  }

  handleKeydown(event) {
    if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
      event.preventDefault()
      this.open()
    }

    if (event.key === "Escape" && !this.modalTarget.classList.contains("hidden")) {
      this.close()
    }
  }
}
