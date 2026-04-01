import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  scroll(event) {
    const { sectionId } = event.params
    const target = document.getElementById(sectionId)

    if (!target) return

    event.preventDefault()
    target.scrollIntoView({ behavior: "smooth", block: "start" })
  }
}
