import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["label"]
  static values = {
    receipt: Object,
    markUrl: String,
    filename: String
  }

  connect() {
    this.originalLabel = this.hasLabelTarget ? this.labelTarget.textContent : "Share Receipt Image"
    this.logo = new Image()
    this.logo.src = "/icons/msj-portal-192x192-20260713.png"
  }

  async share(event) {
    event.preventDefault()
    if (this.element.disabled) return

    this.setBusy(true)

    try {
      const file = this.buildReceiptFile()

      if (this.canShareFile(file)) {
        await navigator.share({
          files: [file],
          title: "MSJ Payment Receipt",
          text: `Mizo Society of Japan payment receipt ${this.receiptValue.receipt_number}`
        })
        await this.markShared()
        this.setLabel("Receipt Shared")
      } else {
        this.download(file)
        this.setLabel("Image Downloaded")
      }
    } catch (error) {
      this.setLabel(error?.name === "AbortError" ? this.originalLabel : "Try Again")
    } finally {
      this.setBusy(false)
    }
  }

  canShareFile(file) {
    if (!navigator.share || !navigator.canShare) return false

    try {
      return navigator.canShare({ files: [file] })
    } catch (_error) {
      return false
    }
  }

  buildReceiptFile() {
    const canvas = this.drawReceipt()
    const dataUrl = canvas.toDataURL("image/png")
    const binary = atob(dataUrl.split(",")[1])
    const bytes = new Uint8Array(binary.length)

    for (let index = 0; index < binary.length; index += 1) {
      bytes[index] = binary.charCodeAt(index)
    }

    return new File([bytes], this.filenameValue, { type: "image/png" })
  }

  drawReceipt() {
    const logicalWidth = 600
    const scale = 2
    const padding = 42
    const receipt = this.receiptValue
    const estimatedHeight = 900 + (receipt.items?.length || 0) * 110
    const canvas = document.createElement("canvas")
    canvas.width = logicalWidth * scale
    canvas.height = estimatedHeight * scale

    const context = canvas.getContext("2d")
    context.scale(scale, scale)
    context.fillStyle = "#FFFFFF"
    context.fillRect(0, 0, logicalWidth, estimatedHeight)
    context.textBaseline = "top"

    let y = 30
    y = this.drawHeader(context, logicalWidth, y)
    y = this.drawRule(context, padding, logicalWidth - padding, y + 20)
    y = this.drawMeta(context, receipt, padding, logicalWidth - padding, y + 22)
    y = this.drawRule(context, padding, logicalWidth - padding, y + 18)
    y = this.drawItems(context, receipt.items || [], padding, logicalWidth - padding, y + 18)
    y = this.drawRule(context, padding, logicalWidth - padding, y + 4)
    y = this.drawTotal(context, receipt.total, padding, logicalWidth - padding, y + 18)
    y = this.drawPaidStamp(context, padding, logicalWidth - padding, y + 22)
    y = this.drawPaymentDetails(context, receipt, padding, logicalWidth - padding, y + 22)
    y = this.drawRule(context, padding, logicalWidth - padding, y + 18)
    y = this.drawFooter(context, logicalWidth, y + 22)

    const finalHeight = Math.ceil(y + 34)
    const cropped = document.createElement("canvas")
    cropped.width = logicalWidth * scale
    cropped.height = finalHeight * scale
    cropped.getContext("2d").drawImage(canvas, 0, 0, cropped.width, cropped.height, 0, 0, cropped.width, cropped.height)
    return cropped
  }

  drawHeader(context, width, y) {
    const logoSize = 74
    const logoX = (width - logoSize) / 2

    if (this.logo?.complete && this.logo.naturalWidth > 0) {
      context.save()
      context.beginPath()
      context.arc(width / 2, y + logoSize / 2, logoSize / 2, 0, Math.PI * 2)
      context.clip()
      context.drawImage(this.logo, logoX, y, logoSize, logoSize)
      context.restore()
    } else {
      context.fillStyle = "#B91C1C"
      context.beginPath()
      context.arc(width / 2, y + logoSize / 2, logoSize / 2, 0, Math.PI * 2)
      context.fill()
      this.drawCentered(context, "MSJ", width / 2, y + 23, "800 22px Arial", "#FFFFFF")
    }

    this.drawCentered(context, "MIZO SOCIETY OF JAPAN", width / 2, y + 90, "800 22px Arial", "#0F172A")
    this.drawCentered(context, "OFFICIAL PAYMENT RECEIPT", width / 2, y + 122, "700 13px Arial", "#64748B")
    return y + 146
  }

  drawMeta(context, receipt, left, right, y) {
    y = this.drawKeyValue(context, "Receipt No.", receipt.receipt_number, left, right, y)
    y = this.drawKeyValue(context, "Date", receipt.date, left, right, y)
    y = this.drawKeyValue(context, "Member", receipt.member, left, right, y)
    return this.drawKeyValue(context, "Member No.", receipt.member_number, left, right, y)
  }

  drawItems(context, items, left, right, y) {
    context.fillStyle = "#0F172A"
    context.font = "800 13px Arial"
    context.fillText("PAYMENT / FUND", left, y)
    context.textAlign = "right"
    context.fillText("AMOUNT", right, y)
    context.textAlign = "left"
    y += 26

    context.strokeStyle = "#0F172A"
    context.lineWidth = 1.5
    context.beginPath()
    context.moveTo(left, y)
    context.lineTo(right, y)
    context.stroke()
    y += 15

    items.forEach((item) => {
      context.font = "800 16px Arial"
      const nameLines = this.wrapLines(context, item.name, 330)
      nameLines.forEach((line, index) => {
        context.fillStyle = "#0F172A"
        context.fillText(line, left, y + index * 21)
      })

      context.textAlign = "right"
      context.font = "800 16px Arial"
      context.fillText(item.amount, right, y)
      context.textAlign = "left"

      const nameHeight = Math.max(21, nameLines.length * 21)
      context.fillStyle = "#64748B"
      context.font = "600 13px Arial"
      const detailLines = this.wrapLines(context, item.detail, 390)
      detailLines.forEach((line, index) => context.fillText(line, left, y + nameHeight + 5 + index * 18))

      y += nameHeight + 10 + detailLines.length * 18 + 14
      context.strokeStyle = "#CBD5E1"
      context.setLineDash([5, 5])
      context.beginPath()
      context.moveTo(left, y)
      context.lineTo(right, y)
      context.stroke()
      context.setLineDash([])
      y += 15
    })

    return y
  }

  drawTotal(context, total, left, right, y) {
    context.fillStyle = "#0F172A"
    context.font = "800 16px Arial"
    context.fillText("TOTAL PAID", left, y + 8)
    context.textAlign = "right"
    context.font = "800 32px Arial"
    context.fillText(total, right, y)
    context.textAlign = "left"
    return y + 42
  }

  drawPaidStamp(context, left, right, y) {
    context.strokeStyle = "#0F172A"
    context.lineWidth = 3
    context.strokeRect(left, y, right - left, 52)
    this.drawCentered(context, "PAID", (left + right) / 2, y + 12, "800 24px Arial", "#0F172A")
    return y + 52
  }

  drawPaymentDetails(context, receipt, left, right, y) {
    y = this.drawKeyValue(context, "Method", receipt.method, left, right, y)
    y = this.drawKeyValue(context, "Reference", receipt.reference, left, right, y)
    return this.drawKeyValue(context, "Approved by", receipt.approved_by, left, right, y)
  }

  drawFooter(context, width, y) {
    this.drawCentered(context, "Thank you for your payment.", width / 2, y, "800 15px Arial", "#0F172A")
    this.drawCentered(context, "Please keep this receipt for your records.", width / 2, y + 26, "600 13px Arial", "#64748B")
    this.drawCentered(context, this.receiptValue.receipt_number, width / 2, y + 54, "600 12px monospace", "#64748B")
    return y + 72
  }

  drawKeyValue(context, label, value, left, right, y) {
    context.fillStyle = "#64748B"
    context.font = "700 14px Arial"
    context.fillText(label, left, y)

    context.fillStyle = "#0F172A"
    context.font = "800 14px Arial"
    context.textAlign = "right"
    const lines = this.wrapLines(context, String(value || "-"), 330)
    lines.forEach((line, index) => context.fillText(line, right, y + index * 19))
    context.textAlign = "left"
    return y + Math.max(30, lines.length * 19 + 9)
  }

  drawRule(context, left, right, y) {
    context.strokeStyle = "#0F172A"
    context.lineWidth = 1.5
    context.beginPath()
    context.moveTo(left, y)
    context.lineTo(right, y)
    context.stroke()
    return y
  }

  drawCentered(context, text, x, y, font, color) {
    context.font = font
    context.fillStyle = color
    context.textAlign = "center"
    context.fillText(text, x, y)
    context.textAlign = "left"
  }

  wrapLines(context, text, maxWidth) {
    const words = String(text || "-").split(/\s+/).flatMap((word) => this.splitLongWord(context, word, maxWidth))
    const lines = []
    let line = ""

    words.forEach((word) => {
      const candidate = line ? `${line} ${word}` : word
      if (line && context.measureText(candidate).width > maxWidth) {
        lines.push(line)
        line = word
      } else {
        line = candidate
      }
    })

    if (line) lines.push(line)
    return lines.length ? lines : ["-"]
  }

  splitLongWord(context, word, maxWidth) {
    if (context.measureText(word).width <= maxWidth) return [word]

    const chunks = []
    let chunk = ""
    Array.from(word).forEach((character) => {
      const candidate = `${chunk}${character}`
      if (chunk && context.measureText(candidate).width > maxWidth) {
        chunks.push(chunk)
        chunk = character
      } else {
        chunk = candidate
      }
    })
    if (chunk) chunks.push(chunk)
    return chunks
  }

  download(file) {
    const url = URL.createObjectURL(file)
    const link = document.createElement("a")
    link.href = url
    link.download = file.name
    document.body.appendChild(link)
    link.click()
    link.remove()
    URL.revokeObjectURL(url)
  }

  async markShared() {
    if (!this.hasMarkUrlValue) return

    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    try {
      await fetch(this.markUrlValue, {
        method: "PATCH",
        credentials: "same-origin",
        headers: {
          Accept: "application/json",
          "X-CSRF-Token": csrfToken
        }
      })
    } catch (_error) {
      // The image was shared successfully even if status tracking is unavailable.
    }
  }

  setBusy(busy) {
    this.element.disabled = busy
    this.element.setAttribute("aria-busy", busy ? "true" : "false")
    if (busy) this.setLabel("Preparing Image...")
  }

  setLabel(text) {
    if (this.hasLabelTarget) this.labelTarget.textContent = text
  }
}
