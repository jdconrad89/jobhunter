import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    interval: { type: Number, default: 3000 },
    maxAttempts: { type: Number, default: 40 }
  }

  static targets = ["status"]

  connect() {
    this.attempts = 0
    this.poll()
    this.timer = setInterval(() => this.poll(), this.intervalValue)
  }

  disconnect() {
    this.stop()
  }

  stop() {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }
  }

  async poll() {
    this.attempts += 1

    if (this.attempts > this.maxAttemptsValue) {
      this.stop()
      this.showTimeout()
      return
    }

    try {
      const response = await fetch(this.urlValue, {
        headers: { Accept: "application/json" },
        credentials: "same-origin"
      })

      if (!response.ok) return

      const data = await response.json()

      if (data.status === "pending") {
        if (data.error_message && this.hasStatusTarget) {
          this.statusTarget.textContent = data.error_message
        }
        return
      }

      this.stop()
      window.location.reload()
    } catch (_error) {
      // Ignore transient network errors and keep polling until max attempts.
    }
  }

  showTimeout() {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent =
        "Suggestion generation is taking too long. Wait a minute, then click Get Suggestions again."
    }
  }
}
