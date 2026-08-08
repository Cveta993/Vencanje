import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "status",
    "attendingFields",
    "adultCount",
    "childCount",
    "adultNames",
    "childNames",
    "childSection",
    "adultTemplate",
    "childTemplate"
  ]

  static values = {
    maxGuests: { type: Number, default: 20 },
    defaultAdultName: String
  }

  connect() {
    this.updateAttendance()
  }

  attendanceChanged() {
    this.updateAttendance()
  }

  adultCountChanged() {
    this.keepTotalWithinLimit("adult")
    this.syncGuestRows()
  }

  childCountChanged() {
    this.keepTotalWithinLimit("child")
    this.syncGuestRows()
  }

  updateAttendance() {
    const attending = this.selectedAttendance === "attending"

    this.attendingFieldsTarget.hidden = !attending
    this.attendingFieldsTarget.querySelectorAll("input, select").forEach((field) => {
      field.disabled = !attending
    })

    if (attending) {
      if (this.count(this.adultCountTarget) < 1) this.adultCountTarget.value = "1"
      this.keepTotalWithinLimit("adult")
      this.syncGuestRows()
    }
  }

  syncGuestRows() {
    this.syncRows({
      container: this.adultNamesTarget,
      template: this.adultTemplateTarget,
      count: this.count(this.adultCountTarget),
      type: "adult",
      label: "Odrasla osoba"
    })

    const childCount = this.count(this.childCountTarget)
    this.childSectionTarget.hidden = childCount === 0
    this.syncRows({
      container: this.childNamesTarget,
      template: this.childTemplateTarget,
      count: childCount,
      type: "child",
      label: "Dete"
    })

    this.updateAvailableCounts()
  }

  syncRows({ container, template, count, type, label }) {
    const rows = Array.from(container.querySelectorAll("[data-guest-name-row]"))

    while (rows.length > count) rows.pop().remove()

    while (rows.length < count) {
      const row = template.content.firstElementChild.cloneNode(true)
      const input = row.querySelector("input")
      if (type === "adult" && rows.length === 0 && this.hasDefaultAdultNameValue) {
        input.value = this.defaultAdultNameValue
      }
      container.append(row)
      rows.push(row)
    }

    rows.forEach((row, index) => {
      const input = row.querySelector("input")
      const inputId = `rsvp_${type}_name_${index}`
      row.querySelector("label").textContent = `${label} ${index + 1}`
      row.querySelector("label").htmlFor = inputId
      input.id = inputId
      input.name = `rsvp[${type}_names][]`
      input.required = true
      input.disabled = false
    })
  }

  keepTotalWithinLimit(changedType) {
    let adults = this.count(this.adultCountTarget)
    let children = this.count(this.childCountTarget)

    if (adults + children <= this.maxGuestsValue) return

    if (changedType === "adult") {
      children = Math.max(0, this.maxGuestsValue - adults)
      this.childCountTarget.value = String(children)
    } else {
      adults = Math.max(1, this.maxGuestsValue - children)
      this.adultCountTarget.value = String(adults)
    }
  }

  updateAvailableCounts() {
    const adults = this.count(this.adultCountTarget)
    const children = this.count(this.childCountTarget)

    Array.from(this.adultCountTarget.options).forEach((option) => {
      option.disabled = Number(option.value) + children > this.maxGuestsValue
    })

    Array.from(this.childCountTarget.options).forEach((option) => {
      option.disabled = Number(option.value) + adults > this.maxGuestsValue
    })
  }

  count(select) {
    return Number.parseInt(select.value || "0", 10)
  }

  get selectedAttendance() {
    return this.statusTargets.find((input) => input.checked)?.value
  }
}
