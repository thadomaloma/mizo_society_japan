import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["moonIcon", "sunIcon"]

  connect() {
    this.sync = this.sync.bind(this)
    document.addEventListener("turbo:load", this.sync)
    window.addEventListener("msj:theme-change", this.sync)

    this.sync()
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.sync)
    window.removeEventListener("msj:theme-change", this.sync)
  }

  moonIconTargetConnected() {
    this.sync()
  }

  sunIconTargetConnected() {
    this.sync()
  }

  toggle() {
    const nextTheme = document.documentElement.classList.contains("dark") ? "light" : "dark"
    this.apply(nextTheme)
    localStorage.setItem("msj-theme", nextTheme)
    window.dispatchEvent(new CustomEvent("msj:theme-change", { detail: { theme: nextTheme } }))
  }

  sync(event) {
    this.apply(event?.detail?.theme || this.currentTheme())
  }

  currentTheme() {
    const storedTheme = localStorage.getItem("msj-theme")
    const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches

    return storedTheme || (prefersDark ? "dark" : "light")
  }

  apply(theme) {
    const dark = theme === "dark"

    document.documentElement.classList.toggle("dark", dark)
    this.element.setAttribute("data-theme", dark ? "dark" : "light")
    this.moonIconTargets.forEach((icon) => icon.classList.toggle("hidden", dark))
    this.sunIconTargets.forEach((icon) => icon.classList.toggle("hidden", !dark))
    this.element.querySelectorAll("[data-action~='theme#toggle']").forEach((button) => {
      const label = dark ? "Switch to light mode" : "Switch to dark mode"
      button.setAttribute("aria-label", label)
      button.setAttribute("title", label)
      button.setAttribute("aria-pressed", dark ? "true" : "false")
    })
  }
}
