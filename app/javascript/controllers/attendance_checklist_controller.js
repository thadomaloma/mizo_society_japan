import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "presentList", "absentList", "presentCount", "absentCount"]

  connect() {
    this.sync()
  }

  sync() {
    const present = this.inputTargets.filter((input) => input.checked)
    const absent = this.inputTargets.filter((input) => !input.checked)

    this.renderMembers(this.presentListTarget, present, "No members marked present.")
    this.renderMembers(this.absentListTarget, absent, "No members marked absent.")
    this.presentCountTarget.textContent = present.length
    this.absentCountTarget.textContent = absent.length
  }

  renderMembers(container, inputs, emptyMessage) {
    container.value = inputs.length
      ? inputs.map((input, index) => `${index + 1}. ${input.dataset.attendanceChecklistName} (${input.dataset.attendanceChecklistRole})`).join("\n")
      : emptyMessage
  }
}
