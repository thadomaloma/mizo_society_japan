import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.preventGesture = (event) => event.preventDefault()
    this.preventMultiTouch = (event) => {
      if (event.touches && event.touches.length > 1) event.preventDefault()
    }

    document.addEventListener("gesturestart", this.preventGesture, { passive: false })
    document.addEventListener("gesturechange", this.preventGesture, { passive: false })
    document.addEventListener("gestureend", this.preventGesture, { passive: false })
    document.addEventListener("touchmove", this.preventMultiTouch, { passive: false })
  }

  disconnect() {
    document.removeEventListener("gesturestart", this.preventGesture)
    document.removeEventListener("gesturechange", this.preventGesture)
    document.removeEventListener("gestureend", this.preventGesture)
    document.removeEventListener("touchmove", this.preventMultiTouch)
  }
}
