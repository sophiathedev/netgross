import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitButton", "form", "insuranceRateField"]
  static values = { calculating: Boolean }

  connect() {
    this.setupInsuranceTypeToggle()
    this.setupNumberFormatting()
    this.setupTurboListeners()
    this.setupCustomEventListeners()
  }

  setupCustomEventListeners() {
    this.element.addEventListener('refresh-form', () => {
      setTimeout(() => {
        this.setupNumberFormatting()
        this.setupInsuranceTypeToggle()
      }, 100)
    })
  }

  clearResultImmediately() {
    const resultContainer = document.getElementById('calculation_result')
    if (resultContainer) {
      resultContainer.innerHTML = `
        <div class="bg-blue-50 border border-blue-200 rounded-xl p-6 text-center">
          <div class="text-blue-400 mb-4">
            <div class="animate-spin mx-auto h-12 w-12 border-4 border-blue-200 border-t-blue-600 rounded-full"></div>
          </div>
          <p class="text-blue-600 font-medium">Đang tính toán thuế TNCN...</p>
        </div>
      `
    }
  }

  disconnect() {
    const numberInputs = this.element.querySelectorAll('input[inputmode="numeric"], input[type="number"]')
    numberInputs.forEach(input => {
      input.removeEventListener('blur', input._formatHandler)
      input.removeEventListener('focus', input._unformatHandler)
    })

    const insuranceTypeRadios = this.element.querySelectorAll('input[name="insurance_type"]')
    insuranceTypeRadios.forEach(radio => {
      radio.removeEventListener('change', radio._toggleHandler)
    })
  }

  setupTurboListeners() {
    document.addEventListener('turbo:submit-start', (event) => {
      if (event.target === this.formTarget) {
        this.calculatingValue = true
        this.clearResultImmediately()
      }
    })

    document.addEventListener('turbo:submit-end', (event) => {
      if (event.target === this.formTarget) {
        this.calculatingValue = false
      }
    })
  }

  setupInsuranceTypeToggle() {
    const insuranceTypeRadios = this.element.querySelectorAll('input[name="insurance_type"]')
    
    insuranceTypeRadios.forEach(radio => {
      radio.removeEventListener('change', radio._toggleHandler)
      radio._toggleHandler = this.toggleInsuranceRateField.bind(this)
      radio.addEventListener('change', radio._toggleHandler)
    })
    
    this.toggleInsuranceRateField()
  }

  setupNumberFormatting() {
    const numberInputs = this.element.querySelectorAll('input[inputmode="numeric"]:not([type="number"])')
    numberInputs.forEach(input => {
      input.removeEventListener('blur', input._formatHandler)
      input.removeEventListener('focus', input._unformatHandler)
      input._formatHandler = () => this.formatNumber(input)
      input._unformatHandler = () => this.unformatNumber(input)
      input.addEventListener('blur', input._formatHandler)
      input.addEventListener('focus', input._unformatHandler)
    })
  }

  toggleInsuranceRateField() {
    const checkedRadio = this.element.querySelector('input[name="insurance_type"]:checked')
    const insuranceRateField = this.insuranceRateFieldTarget
    
    if (checkedRadio && checkedRadio.value === 'fixed_amount') {
      insuranceRateField.style.display = 'block'
    } else {
      insuranceRateField.style.display = 'none'
    }
  }

  formatNumber(input) {
    let value = input.value.replace(/\./g, '')
    if (value && !isNaN(value)) {
      value = parseInt(value).toLocaleString('vi-VN')
      input.value = value
    }
  }

  unformatNumber(input) {
    const oldValue = input.value
    input.value = input.value.replace(/\./g, '')
    
    if (!input.value && oldValue) {
      input.value = oldValue.replace(/[^\d]/g, '')
    }
  }

  submitForm(event) {
    if (this.calculatingValue) {
      event.preventDefault()
      return
    }
    
    const numberInputs = this.element.querySelectorAll('input[inputmode="numeric"], input[type="number"]')
    numberInputs.forEach(input => this.unformatNumber(input))
    
    this.calculatingValue = true
    this.updateSubmitButtonState()
  }

  calculatingValueChanged() {
    this.updateSubmitButtonState()
  }

  updateSubmitButtonState() {
    if (this.calculatingValue) {
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.innerHTML = 'Đang tính toán...'
    } else {
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.innerHTML = 'Tính Thuế TNCN'
    }
  }
}
