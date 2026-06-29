import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["postalCode", "prefecture", "city", "addressLine1", "message"]

  lookupWhenReady() {
    clearTimeout(this.lookupTimer)
    const postalCode = this.postalCodeTarget.value.replace(/\D/g, "")

    if (postalCode.length !== 7) return

    this.lookupTimer = setTimeout(() => this.lookup(), 350)
  }

  async lookup() {
    const postalCode = this.postalCodeTarget.value.replace(/\D/g, "")

    if (postalCode.length !== 7) {
      this.setMessage("Enter a 7 digit Japan postal code.", true)
      return
    }

    this.setMessage("Looking up postal code...")

    try {
      const response = await fetch(`https://zipcloud.ibsnet.co.jp/api/search?zipcode=${postalCode}`)
      const data = await response.json()
      const result = data.results?.[0]

      if (!result) {
        this.setMessage("Postal code not found. Please enter address manually.", true)
        return
      }

      this.prefectureTarget.value = result.address1 || ""
      this.cityTarget.value = result.address2 || ""
      this.addressLine1Target.value = result.address3 || ""
      this.setMessage("Prefecture, city, and town area filled.")
    } catch (_error) {
      this.setMessage("Postal lookup is unavailable. Please enter address manually.", true)
    }
  }

  setMessage(message, isError = false) {
    this.messageTarget.textContent = message
    this.messageTarget.classList.toggle("text-red-700", isError)
  }
}
