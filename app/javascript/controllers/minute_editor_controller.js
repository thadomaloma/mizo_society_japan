import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["agenda", "agendaPanel", "agendaPoint", "decisions", "decisionButton"]

  connect() {
    this.refreshAgendaPoints()
  }

  insertAgenda() {
    this.showAgendaEditor()
    this.appendNumberedLine(this.agendaTarget)
    this.refreshAgendaPoints()
  }

  refreshAgendaPoints() {
    const selectedValue = this.agendaPointTarget.value
    const items = this.agendaItems()
    const options = [new Option(items.length ? "Select an agenda point" : "Add agenda items first", "")]

    items.forEach((item) => {
      const option = new Option(`${item.number}. ${item.text}`, item.number)
      option.dataset.agendaText = item.text
      options.push(option)
    })
    this.agendaPointTarget.replaceChildren(...options)
    this.agendaPointTarget.value = items.some((item) => item.number === selectedValue) ? selectedValue : ""
    this.decisionButtonTarget.disabled = items.length === 0
  }

  insertDecision() {
    const agendaNumber = this.agendaPointTarget.value
    if (!agendaNumber) {
      this.agendaPointTarget.focus()
      return
    }

    const agendaText = this.agendaPointTarget.selectedOptions[0]?.dataset.agendaText || "Agenda item"
    const decisionLine = this.buildNumberedLine(this.decisionsTarget, "")
    const agendaTitle = document.createElement("strong")

    agendaTitle.textContent = `${agendaText}:`
    decisionLine.append(agendaTitle, " ")
    this.appendLine(this.decisionsTarget, decisionLine)
    this.moveCursorToEnd(decisionLine)
    this.syncEditor(this.decisionsTarget)
  }

  agendaItems() {
    return this.agendaTarget.innerText
      .split("\n")
      .map((line, index) => {
        const trimmed = line.trim()
        const match = trimmed.match(/^(\d+)[.)]\s+(.+)$/)
        return trimmed ? { number: match?.[1] || String(index + 1), text: match?.[2] || trimmed } : null
      })
      .filter(Boolean)
  }

  continueNumbering(event) {
    if (event.key !== "Enter" || event.shiftKey || event.metaKey || event.ctrlKey || event.altKey) return
    if (event.target !== this.agendaTarget && event.target !== this.decisionsTarget) return

    const currentLine = this.currentLineText(event.target)
    if (!currentLine.match(/^\s*\d+[.)]\s+/)) return

    event.preventDefault()
    this.insertNumberedLineAtCursor(event.target)
  }

  appendNumberedLine(editor) {
    const line = this.buildNumberedLine(editor)
    this.appendLine(editor, line)
    this.moveCursorToEnd(line, editor)
    this.syncEditor(editor)
  }

  insertNumberedLineAtCursor(editor) {
    const line = this.buildNumberedLine(editor)
    const currentLine = this.currentLineElement(editor)

    if (currentLine && currentLine !== editor) {
      currentLine.after(line)
    } else {
      this.appendLine(editor, line)
    }

    this.moveCursorToEnd(line, editor)
    this.syncEditor(editor)
  }

  buildNumberedLine(editor, trailingText = "\u00A0") {
    const line = document.createElement("div")
    line.append(`${this.nextNumber(editor.innerText)}. `, trailingText)
    return line
  }

  appendLine(editor, line) {
    if (editor.innerText.trim().length) {
      editor.append(line)
    } else {
      editor.replaceChildren(line)
    }
  }

  nextNumber(value) {
    const numbers = Array.from(value.matchAll(/^\s*(\d+)[.)]\s+/gm), (match) => Number(match[1]))
    return numbers.length ? Math.max(...numbers) + 1 : 1
  }

  moveCursorToEnd(element, editor = this.decisionsTarget) {
    const range = document.createRange()
    const selection = window.getSelection()

    editor.focus()
    range.selectNodeContents(element)
    range.collapse(false)
    selection.removeAllRanges()
    selection.addRange(range)
  }

  currentLineElement(editor) {
    const selection = window.getSelection()
    if (!selection?.rangeCount || !editor.contains(selection.anchorNode)) return null

    let node = selection.anchorNode
    while (node && node !== editor && node.parentNode !== editor) {
      node = node.parentNode
    }

    return node
  }

  currentLineText(editor) {
    const selection = window.getSelection()
    if (!selection?.rangeCount || !editor.contains(selection.anchorNode)) return ""

    const node = this.currentLineElement(editor)

    return (node?.textContent || "").trim()
  }

  syncEditor(editor) {
    editor.dispatchEvent(new Event("input", { bubbles: true }))
  }

  showAgendaEditor() {
    this.agendaPanelTarget.classList.remove("hidden")
  }
}
