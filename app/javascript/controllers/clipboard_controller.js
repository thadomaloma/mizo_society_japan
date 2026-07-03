import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }
  static targets = ["label"]

  async copy() {
    if (!this.textValue) return

    try {
      await navigator.clipboard.writeText(this.textValue)
      this.showCopied()
    } catch (_error) {
      this.fallbackCopy()
      this.showCopied()
    }
  }

  fallbackCopy() {
    const textarea = document.createElement("textarea")
    textarea.value = this.textValue
    textarea.setAttribute("readonly", "")
    textarea.style.position = "absolute"
    textarea.style.left = "-9999px"
    document.body.appendChild(textarea)
    textarea.select()
    document.execCommand("copy")
    document.body.removeChild(textarea)
  }

  showCopied() {
    if (!this.hasLabelTarget) return

    const original = this.labelTarget.textContent
    this.labelTarget.textContent = "Copied"

    window.setTimeout(() => {
      this.labelTarget.textContent = original
    }, 1200)
  }
}
