import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "foodIdInput", "foodName", "caloriesInput"]
  static values = { open: Boolean }

  connect() {
    this.sync()
  }

  show(event) {
    const { foodId, foodName, foodCalories } = event.params

    this.foodIdInputTarget.value = foodId
    this.foodNameTarget.textContent = foodName
    this.caloriesInputTarget.value = ""
    this.caloriesInputTarget.placeholder = foodCalories
    this.openValue = true
    this.sync()
    this.caloriesInputTarget.focus()
  }

  hide() {
    this.openValue = false
    this.sync()
  }

  submitEnd(event) {
    if (!event.detail.success) return

    this.hide()
    this.caloriesInputTarget.value = ""
  }

  sync() {
    const isOpen = this.openValue

    this.formTarget.classList.toggle("hidden", !isOpen)
  }
}
