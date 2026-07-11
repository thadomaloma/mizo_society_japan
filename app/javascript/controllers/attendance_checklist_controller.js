import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["presentInput", "apologyInput", "apologyOption", "presentList", "presentCount", "apologyCount"]

  connect() {
    this.sync()
  }

  sync() {
    const present = this.presentInputTargets.filter((input) => input.checked)
    const presentIds = new Set(present.map((input) => input.value))

    this.apologyOptionTargets.forEach((option) => {
      const hidden = presentIds.has(option.dataset.userId)
      const input = option.querySelector("input[type='checkbox']")

      option.classList.toggle("hidden", hidden)
      if (hidden && input) input.checked = false
    })

    const apologies = this.apologyInputTargets.filter((input) => input.checked && !presentIds.has(input.value))

    this.renderMembers(this.presentListTarget, present, "No members marked present.")
    this.presentCountTarget.textContent = present.length
    this.apologyCountTarget.textContent = apologies.length
  }

  renderMembers(container, inputs, emptyMessage) {
    container.value = inputs.length
      ? inputs.map((input, index) => `${index + 1}. ${input.dataset.attendanceChecklistName} (${input.dataset.attendanceChecklistRole})`).join("\n")
      : emptyMessage
  }
}
