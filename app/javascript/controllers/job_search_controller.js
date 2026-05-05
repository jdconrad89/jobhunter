import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["urlInput", "urlContainer", "addButton", "limitMessage"]

  connect() {
    this.MAX_URLS = 10
    this.initializeValidation()
    this.updateAddButton()
  }

  addUrl(event) {
    event.preventDefault()
    const currentUrls = this.urlContainerTarget.querySelectorAll('.board-url-input').length
    
    if (currentUrls < this.MAX_URLS) {
      this.urlContainerTarget.appendChild(this.createUrlInput())
      this.updateAddButton()
    }
  }

  removeUrl(event) {
    event.preventDefault()
    event.target.closest('.board-url-input').remove()
    this.updateAddButton()
  }

  validateUrl(event) {
    const input = event.target
    const message = input.parentElement.querySelector('.url-validation-message')
    const url = input.value.trim()
    
    if (!url) {
      message.textContent = ''
      message.className = 'url-validation-message'
      return true
    }

    try {
      new URL(url)
      if (url.startsWith('http://') || url.startsWith('https://')) {
        message.textContent = '✓ Valid URL'
        message.className = 'url-validation-message success'
        return true
      } else {
        message.textContent = 'URL must start with http:// or https://'
        message.className = 'url-validation-message error'
        return false
      }
    } catch {
      message.textContent = 'Please enter a valid URL'
      message.className = 'url-validation-message error'
      return false
    }
  }

  validateForm(event) {
    const urlInputs = this.urlInputTargets
    let isValid = true

    urlInputs.forEach(input => {
      if (!this.validateUrl({ target: input })) {
        isValid = false
      }
    })

    if (!isValid) {
      event.preventDefault()
      alert('Please fix the invalid URLs before submitting.')
    }
  }

  private

  createUrlInput() {
    const newInput = document.createElement('div')
    newInput.className = 'board-url-input'
    newInput.innerHTML = `
      <div class="url-input-group">
        <div style="display: flex; gap: 0.5rem;">
          <input type="text" 
                 name="job_search[board_relevance][]" 
                 class="form-input url-input" 
                 data-job-search-target="urlInput"
                 placeholder="https://www.linkedin.com/jobs/search/"
                 pattern="^https?://.+"
                 title="URL must start with http:// or https://">
          <button type="button" 
                  class="form-submit remove-url-button" 
                  data-action="click->job-search#removeUrl">Remove</button>
        </div>
        <div class="url-validation-message"></div>
      </div>
    `

    const input = newInput.querySelector('input')
    input.addEventListener('input', (e) => this.validateUrl(e))
    input.addEventListener('blur', (e) => this.validateUrl(e))

    return newInput
  }

  updateAddButton() {
    const currentUrls = this.urlContainerTarget.querySelectorAll('.board-url-input').length
    if (currentUrls >= this.MAX_URLS) {
      this.addButtonTarget.style.display = 'none'
      this.limitMessageTarget.style.display = 'block'
    } else {
      this.addButtonTarget.style.display = 'block'
      this.limitMessageTarget.style.display = 'none'
    }
  }

  initializeValidation() {
    this.urlInputTargets.forEach(input => {
      input.addEventListener('input', (e) => this.validateUrl(e))
      input.addEventListener('blur', (e) => this.validateUrl(e))
    })
  }
} 