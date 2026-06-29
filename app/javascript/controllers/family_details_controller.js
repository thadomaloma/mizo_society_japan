import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "familyFields", "childrenList", "childTemplate", "childRow", "destroyInput"]

  connect() {
    this.toggle()
  }

  toggle() {
    if (!this.hasFamilyFieldsTarget) return

    this.familyFieldsTarget.classList.toggle("hidden", this.selectedStatus() !== "family")
  }

  addChild() {
    const content = this.childTemplateTarget.innerHTML.replaceAll("NEW_CHILD", Date.now().toString())
    this.childrenListTarget.insertAdjacentHTML("beforeend", content)
  }

  removeChild(event) {
    const row = event.target.closest("[data-family-details-target='childRow']")
    if (!row) return

    const destroyInput = row.querySelector("input[name$='[_destroy]']")
    const idInput = row.querySelector("input[name$='[id]']")

    if (destroyInput && idInput?.value) {
      destroyInput.value = "1"
      row.classList.add("hidden")
    } else {
      row.remove()
    }
  }

  selectedStatus() {
    return this.statusTargets.find((input) => input.checked)?.value
  }
}
