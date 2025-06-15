import * as BrutJS from "./index.js"
document.addEventListener("DOMContentLoaded", () => {
  BrutJS.BrutCustomElements.define()
  if (!HTMLDialogElement.prototype.showModal) {
    HTMLDialogElement.prototype.showModal = function() {
      this.open = true
    }
  }
  if (!HTMLDialogElement.prototype.close) {
    HTMLDialogElement.prototype.close = function(returnValue) {
      this.open = false
      this.returnValue = returnValue
    }
  }
})
