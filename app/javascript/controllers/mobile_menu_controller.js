import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["drawer", "panel"]

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.handleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
    document.body.classList.remove("overflow-hidden")
  }

  open(event) {
    event?.preventDefault()
    this.drawerTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    requestAnimationFrame(() => this.panelTarget.classList.remove("-translate-x-full"))
  }

  close(event) {
    this.panelTarget.classList.add("-translate-x-full")
    document.body.classList.remove("overflow-hidden")
    window.setTimeout(() => this.drawerTarget.classList.add("hidden"), 200)
  }

  closeFromBackdrop(event) {
    if (event.target === this.drawerTarget) this.close(event)
  }

  handleKeydown(event) {
    if (event.key === "Escape" && !this.drawerTarget.classList.contains("hidden")) this.close()
  }
}
