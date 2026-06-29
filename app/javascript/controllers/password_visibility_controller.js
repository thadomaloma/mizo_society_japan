import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "eyeIcon", "eyeSlashIcon", "button"]

  toggle() {
    const isPassword = this.inputTarget.type === "password"

    this.inputTarget.type = isPassword ? "text" : "password"
    this.buttonTarget.setAttribute("aria-label", isPassword ? "Hide password" : "Show password")
    this.eyeIconTarget.classList.toggle("hidden", isPassword)
    this.eyeSlashIconTarget.classList.toggle("hidden", !isPassword)
  }
}
