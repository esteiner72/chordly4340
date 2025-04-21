import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static classes = ["active"];

  toggle(event) {
    event.preventDefault();
    this.element.classList.toggle("is-active");
  }

  clickOutside = (e) => {
    if (!this.element.contains(e.target)) {
      this.element.classList.remove("is-active");
    }
  }

  connect() {
    document.addEventListener("click", this.clickOutside);
  }
  disconnect() {
    document.removeEventListener("click", this.clickOutside);
  }
}
