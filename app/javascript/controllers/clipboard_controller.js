import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]

  async copy() {
    const value = this.sourceTarget.value

    try {
      await navigator.clipboard.writeText(value)
    } catch (_error) {
      this.sourceTarget.select()
      document.execCommand("copy")
      this.sourceTarget.setSelectionRange(0, 0)
    }

    const originalLabel = this.buttonTarget.textContent
    this.buttonTarget.textContent = "Kopirano ✓"
    this.buttonTarget.disabled = true

    window.setTimeout(() => {
      this.buttonTarget.textContent = originalLabel
      this.buttonTarget.disabled = false
    }, 1800)
  }
}
