import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["confirmation", "send", "label"]
  static values = {
    markOpenedUrl: String,
    compact: Boolean,
    sent: Boolean
  }

  async opened() {
    const tracked = await this.markOpened()

    if (tracked && !this.sentValue) {
      this.confirmationTarget.classList.remove("hidden")

      if (this.compactValue) {
        this.sendTarget.classList.add("hidden")
      } else {
        this.labelTarget.textContent = "Open WhatsApp Again"
      }
    }
  }

  async markOpened() {
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content

    try {
      const response = await fetch(this.markOpenedUrlValue, {
        method: "PATCH",
        credentials: "same-origin",
        headers: {
          Accept: "application/json",
          "X-CSRF-Token": csrfToken
        }
      })
      return response.ok
    } catch (_error) {
      // WhatsApp still opens even if delivery-status tracking is unavailable.
      return false
    }
  }
}
