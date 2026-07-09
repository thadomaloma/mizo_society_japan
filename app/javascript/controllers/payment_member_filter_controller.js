import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["userSelect", "planSelect", "yearInput", "hint"]
  static values = {
    users: Array,
    blocked: Array,
    planCycles: Object,
    currentUserId: Number
  }

  connect() {
    this.filter()
  }

  filter() {
    if (!this.hasUserSelectTarget) return

    const selectedUserId = this.userSelectTarget.value
    const blockedUserIds = this.blockedUserIds()
    const visibleUsers = this.usersValue.filter((user) => {
      const userId = Number.parseInt(user.id, 10)
      return !blockedUserIds.has(userId) || this.keepVisible(userId, selectedUserId)
    })

    this.rebuildUserOptions(visibleUsers, selectedUserId)
    this.updateHint(blockedUserIds.size)
  }

  blockedUserIds() {
    const planId = Number.parseInt(this.planSelectTarget.value, 10)
    if (!planId) return new Set()

    const billingCycle = this.planCyclesValue[String(planId)]
    const paymentYear = Number.parseInt(this.yearInputTarget.value, 10)

    return new Set(
      this.blockedValue
        .filter((record) => this.recordBlocksPlan(record, planId, billingCycle, paymentYear))
        .map((record) => Number.parseInt(record.user_id, 10))
    )
  }

  recordBlocksPlan(record, planId, billingCycle, paymentYear) {
    if (Number.parseInt(record.plan_id, 10) !== planId) return false
    if (billingCycle === "one_time") return true
    if (!paymentYear) return false

    return Number.parseInt(record.payment_year, 10) === paymentYear && record.payment_month === null
  }

  keepVisible(userId, selectedUserId) {
    return userId === Number.parseInt(selectedUserId, 10) || userId === this.currentUserIdValue
  }

  rebuildUserOptions(users, selectedUserId) {
    this.userSelectTarget.innerHTML = ""
    this.userSelectTarget.appendChild(new Option("Select member", ""))

    users.forEach((user) => {
      const option = new Option(user.label, user.id)
      this.userSelectTarget.appendChild(option)
    })

    if (users.some((user) => String(user.id) === String(selectedUserId))) {
      this.userSelectTarget.value = selectedUserId
    }
  }

  updateHint(hiddenCount) {
    if (!this.hasHintTarget) return

    if (hiddenCount > 0) {
      this.hintTarget.textContent = `${hiddenCount} member(s) already have an active or paid record for this plan and period, so they are hidden.`
    } else {
      this.hintTarget.textContent = "Choose the member who paid or needs this record."
    }
  }
}
