import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editor", "input", "button"]

  connect() {
    this.selectionChanged = this.refreshToolbar.bind(this)
    this.formSubmitted = this.sync.bind(this)
    document.addEventListener("selectionchange", this.selectionChanged)
    this.form = this.element.closest("form")
    this.form?.addEventListener("submit", this.formSubmitted)
    this.sync()
    this.refreshToolbar()
  }

  disconnect() {
    document.removeEventListener("selectionchange", this.selectionChanged)
    this.form?.removeEventListener("submit", this.formSubmitted)
  }

  keepFocus(event) {
    const selection = window.getSelection()
    const selectedNode = selection?.anchorNode

    if (selection?.rangeCount && selectedNode && this.editorTarget.contains(selectedNode)) {
      this.selectionRange = selection.getRangeAt(0).cloneRange()
    }

    event.preventDefault()
  }

  format(event) {
    this.restoreSelection()
    document.execCommand(event.params.command, false, null)
    this.sync()
    this.refreshToolbar()
  }

  sync() {
    this.inputTarget.value = this.editorTarget.innerHTML
  }

  refreshToolbar() {
    const selection = window.getSelection()
    const selectedNode = selection?.anchorNode
    const selectionIsInEditor = selectedNode && this.editorTarget.contains(selectedNode)

    if (!selectionIsInEditor && document.activeElement !== this.editorTarget) return

    this.buttonTargets.forEach((button) => {
      const active = document.queryCommandState(button.dataset.simpleRichTextCommandParam)
      button.dataset.active = active ? "true" : "false"
      button.setAttribute("aria-pressed", active ? "true" : "false")
    })
  }

  restoreSelection() {
    this.editorTarget.focus()
    if (!this.selectionRange) return

    const selection = window.getSelection()
    selection.removeAllRanges()
    selection.addRange(this.selectionRange)
  }
}
