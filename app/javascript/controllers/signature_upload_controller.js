import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "message", "filename"]

  connect() {
    this.showExistingState()
  }

  preview() {
    const file = this.inputTarget.files?.[0]
    if (!file) {
      this.showExistingState()
      return
    }

    if (file.type !== "image/png" || !file.name.toLowerCase().endsWith(".png")) {
      this.inputTarget.value = ""
      this.previewTarget.removeAttribute("src")
      this.previewTarget.classList.add("hidden")
      this.filenameTarget.textContent = "No PNG selected"
      this.showMessage("Please choose a PNG signature file.")
      return
    }

    if (file.size > 2 * 1024 * 1024) {
      this.inputTarget.value = ""
      this.previewTarget.removeAttribute("src")
      this.previewTarget.classList.add("hidden")
      this.filenameTarget.textContent = "No PNG selected"
      this.showMessage("Signature PNG must be smaller than 2MB.")
      return
    }

    const imageUrl = URL.createObjectURL(file)
    this.previewTarget.onload = () => {
      if (this.previewTarget.naturalWidth < 300 || this.previewTarget.naturalHeight < 60) {
        URL.revokeObjectURL(imageUrl)
        this.inputTarget.value = ""
        this.previewTarget.removeAttribute("src")
        this.previewTarget.classList.add("hidden")
        this.filenameTarget.textContent = "No PNG selected"
        this.showMessage("Use a clearer PNG, at least 300x60px.")
        return
      }

      URL.revokeObjectURL(imageUrl)
    }
    this.previewTarget.src = imageUrl
    this.previewTarget.classList.remove("hidden")
    this.filenameTarget.textContent = file.name
    this.showMessage("PNG ready. PDF export will only control display size.")
  }

  showExistingState() {
    this.showMessage(this.element.dataset.signatureUploadMessage || "PNG only. Recommended size: at least 300x60px.")
  }

  showMessage(message) {
    this.messageTarget.textContent = message
  }
}
