import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "organizationName",
    "organizationLocation",
    "referenceNumber",
    "datedPlace",
    "letterDate",
    "presidentName",
    "presidentPhone",
    "secretaryName",
    "secretaryPhone",
    "motto",
    "recipientBlock",
    "salutation",
    "subject",
    "body",
    "closing",
    "signerName",
    "signerTitle",
    "previewOrganizationName",
    "previewOrganizationLocation",
    "previewReference",
    "previewDateLine",
    "previewContacts",
    "previewMotto",
    "previewRecipient",
    "previewSalutation",
    "previewSubject",
    "previewBody",
    "previewClosing",
    "previewSigner"
  ]

  connect() {
    this.update()
  }

  update() {
    const organizationName = this.value(this.organizationNameTarget, "MIZO SOCIETY OF JAPAN")
    const organizationLocation = this.value(this.organizationLocationTarget, "TOKYO : JAPAN")
    const referenceNumber = this.value(this.referenceNumberTarget, "MSJ/LET/2026/001")
    const datedPlace = this.value(this.datedPlaceTarget, "Tokyo")
    const letterDate = this.value(this.letterDateTarget, this.defaultDate())
    const presidentName = this.value(this.presidentNameTarget, "President")
    const presidentPhone = this.value(this.presidentPhoneTarget, "+81-XX-XXXX-XXXX")
    const secretaryName = this.value(this.secretaryNameTarget, "Secretary")
    const secretaryPhone = this.value(this.secretaryPhoneTarget, "+81-XX-XXXX-XXXX")

    this.previewOrganizationNameTarget.textContent = organizationName.toUpperCase()
    this.previewOrganizationLocationTarget.textContent = organizationLocation.toUpperCase()
    this.previewReferenceTarget.textContent = `No. ${referenceNumber}`
    this.previewDateLineTarget.textContent = `Dated ${datedPlace} the ${letterDate}`
    this.previewContactsTarget.innerHTML = this.lines([
      `President : ${presidentName}`,
      `Phone : ${presidentPhone}`,
      `Secretary : ${secretaryName}`,
      `Phone : ${secretaryPhone}`
    ].join("\n"))
    this.previewMottoTarget.innerHTML = this.lines(["MOTTO:", ...this.mottoLines()].join("\n"))
    this.previewRecipientTarget.innerHTML = this.lines(this.value(this.recipientBlockTarget, "The President/General Secretary,\nOrganization Name,\nAddress."))
    this.previewSalutationTarget.textContent = this.value(this.salutationTarget, "Dear Sir/Madam,")
    this.previewSubjectTarget.textContent = this.value(this.subjectTarget, "Official communication")
    this.previewBodyTarget.innerHTML = this.paragraphs(this.value(this.bodyTarget, "Mizo Society of Japan hmingin chibai kan buk a che.\n\nHe lehkha hi official communication atan kan siam a ni."))
    this.previewClosingTarget.textContent = this.value(this.closingTarget, "Yours faithfully,")
    this.previewSignerTarget.innerHTML = this.lines([
      this.value(this.signerNameTarget, "Authorized Name"),
      this.value(this.signerTitleTarget, "General Secretary"),
      organizationName
    ].join("\n"))
  }

  value(target, fallback) {
    const value = target.value.trim()
    return value.length > 0 ? value : fallback
  }

  mottoLines() {
    return this.value(this.mottoTarget, "Unity\nCulture\nWelfare")
      .split(/\n+/)
      .map((line) => line.trim())
      .filter((line) => line.length > 0)
      .map((line, index) => `${index + 1}. ${line}`)
  }

  lines(value) {
    return this.escape(value).replace(/\n/g, "<br>")
  }

  paragraphs(value) {
    return this.escape(value)
      .split(/\n{2,}/)
      .map((paragraph) => `<p>${paragraph.replace(/\n/g, "<br>")}</p>`)
      .join("")
  }

  escape(value) {
    const div = document.createElement("div")
    div.textContent = value
    return div.innerHTML
  }

  defaultDate() {
    return new Date().toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric"
    })
  }
}
