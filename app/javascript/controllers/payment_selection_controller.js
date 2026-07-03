import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "total", "count", "submit"]

  connect() {
    this.update()
  }

  update() {
    const checkedBoxes = this.checkboxTargets.filter((checkbox) => checkbox.checked)
    const total = checkedBoxes.reduce((sum, checkbox) => {
      return sum + Number.parseInt(checkbox.dataset.amount || "0", 10)
    }, 0)

    this.totalTargets.forEach((target) => {
      target.textContent = this.formatYen(total)
    })

    this.countTargets.forEach((target) => {
      target.textContent = checkedBoxes.length.toString()
    })

    this.submitTargets.forEach((target) => {
      target.disabled = checkedBoxes.length === 0
    })
  }

  formatYen(amount) {
    return new Intl.NumberFormat("ja-JP", {
      style: "currency",
      currency: "JPY",
      maximumFractionDigits: 0
    }).format(amount)
  }
}
