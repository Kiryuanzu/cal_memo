import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "form"]
  static values = { open: Boolean }

  connect() {
    this.sync()
  }

  show() {
    this.openValue = true
    this.sync()
  }

  hide() {
    this.openValue = false
    this.sync()
  }

  sync() {
    const isOpen = this.openValue

    this.buttonTarget.classList.toggle("hidden", isOpen)
    this.formTarget.classList.toggle("hidden", !isOpen)
  }
}
