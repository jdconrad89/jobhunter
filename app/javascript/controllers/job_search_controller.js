import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["boardNameInput", "boardRelevanceContainer", "addButton", "limitMessage"]

  connect() {
    this.MAX_BOARD_ENTRIES = 10
    this.initializeValidation()
    this.updateAddButton()
  }

  addBoardRow(event) {
    event.preventDefault()
    const count = this.boardRelevanceContainerTarget.querySelectorAll(".board-relevance-row").length

    if (count < this.MAX_BOARD_ENTRIES) {
      this.boardRelevanceContainerTarget.appendChild(this.createBoardRow())
      this.updateAddButton()
    }
  }

  removeBoardRow(event) {
    event.preventDefault()
    event.target.closest(".board-relevance-row").remove()
    this.updateAddButton()
  }

  validateBoardEntry(event) {
    const input = event.target
    const message = input.closest(".url-input-group")?.querySelector(".board-relevance-hint")
    const raw = input.value.trim()

    if (!message) return true

    if (!raw) {
      message.textContent = ""
      message.className = "board-relevance-hint"
      return true
    }

    if (raw.length > 255) {
      message.textContent = "Name must be 255 characters or fewer"
      message.className = "board-relevance-hint error"
      return false
    }

    message.textContent = ""
    message.className = "board-relevance-hint"
    return true
  }

  validateForm(event) {
    let isValid = true

    this.boardNameInputTargets.forEach((input) => {
      if (!this.validateBoardEntry({ target: input })) {
        isValid = false
      }
    })

    if (!isValid) {
      event.preventDefault()
      alert("Please fix invalid job board names before submitting.")
    }
  }

  createBoardRow() {
    const newRow = document.createElement("div")
    newRow.className = "board-relevance-row"
    newRow.innerHTML = `
      <div class="url-input-group">
        <div style="display: flex; gap: 0.5rem;">
          <input type="text"
                 name="job_search[board_relevance][]"
                 class="form-input board-name-input"
                 data-job-search-target="boardNameInput"
                 placeholder="e.g. LinkedIn"
                 maxlength="255">
          <button type="button"
                  class="form-submit remove-url-button"
                  data-action="click->job-search#removeBoardRow">Remove</button>
        </div>
        <div class="board-relevance-hint"></div>
      </div>
    `

    const input = newRow.querySelector("input")
    input.addEventListener("input", (e) => this.validateBoardEntry(e))
    input.addEventListener("blur", (e) => this.validateBoardEntry(e))

    return newRow
  }

  updateAddButton() {
    const count = this.boardRelevanceContainerTarget.querySelectorAll(".board-relevance-row").length
    if (count >= this.MAX_BOARD_ENTRIES) {
      this.addButtonTarget.style.display = "none"
      this.limitMessageTarget.style.display = "block"
    } else {
      this.addButtonTarget.style.display = "block"
      this.limitMessageTarget.style.display = "none"
    }
  }

  initializeValidation() {
    this.boardNameInputTargets.forEach((input) => {
      input.addEventListener("input", (e) => this.validateBoardEntry(e))
      input.addEventListener("blur", (e) => this.validateBoardEntry(e))
    })
  }
}
