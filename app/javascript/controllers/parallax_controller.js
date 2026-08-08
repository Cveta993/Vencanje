import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["layer"]

  connect() {
    this.motionQuery = window.matchMedia("(prefers-reduced-motion: reduce)")
    this.onScroll = this.requestFrame.bind(this)
    this.onResize = this.requestFrame.bind(this)
    this.onMotionChange = this.configureMotion.bind(this)
    this.motionQuery.addEventListener("change", this.onMotionChange)
    this.configureMotion()
  }

  disconnect() {
    this.stop()
    this.motionQuery?.removeEventListener("change", this.onMotionChange)
  }

  configureMotion() {
    this.stop()

    if (this.motionQuery.matches) {
      this.layerTargets.forEach((layer) => layer.style.removeProperty("--parallax-y"))
      return
    }

    window.addEventListener("scroll", this.onScroll, { passive: true })
    window.addEventListener("resize", this.onResize, { passive: true })
    this.requestFrame()
  }

  stop() {
    window.removeEventListener("scroll", this.onScroll)
    window.removeEventListener("resize", this.onResize)
    if (this.frame) cancelAnimationFrame(this.frame)
    this.frame = null
  }

  requestFrame() {
    if (this.frame) return
    this.frame = requestAnimationFrame(() => {
      this.frame = null
      this.updateLayers()
    })
  }

  updateLayers() {
    const viewportHeight = window.innerHeight
    const isCompactViewport = window.matchMedia("(max-width: 900px)").matches
    const motionScale = isCompactViewport ? 0.8 : 1

    this.layerTargets.forEach((layer) => {
      const panel = layer.closest(".story-panel")
      if (!panel) return

      const rect = panel.getBoundingClientRect()
      if (rect.bottom < -100 || rect.top > viewportHeight + 100) return

      const viewportAnchor = Number.parseFloat(layer.dataset.parallaxViewportAnchor)
      if (!isCompactViewport && Number.isFinite(viewportAnchor)) {
        const anchoredTop = viewportHeight * viewportAnchor
        const offset = anchoredTop - rect.top
        layer.style.setProperty("--parallax-y", `${offset.toFixed(2)}px`)
        return
      }

      const speed = Number.parseFloat(layer.dataset.parallaxSpeed || "0.10")
      const maxOffset = Math.min(180, panel.offsetHeight * 0.28)
      const panelDocumentTop = window.scrollY + rect.top
      const travelPastPanel = window.scrollY - panelDocumentTop
      const offset = Math.max(-maxOffset, Math.min(maxOffset, travelPastPanel * speed * motionScale))
      layer.style.setProperty("--parallax-y", `${offset.toFixed(2)}px`)
    })
  }
}
