# frozen_string_literal: true

class Hash
  def to_o
    OpenStruct.new(self)
  end
end

class ConvertGrossToNetService < BaseService
  attr_reader :gross_amount, :dependent_count, :tax_area, :insurance_type, :insurance_rate

  DEDUCTION_FROM_AREAS = [4_960_000, 4_410_000, 3_860_000, 3_450_000] # Giảm trừ theo khu vực
  PERSONAL_FAMILY_DEDUCTION = 11_000_000 # Giảm trừ gia cảnh cá nhân
  DEPENDENT_DEDUCTION = 4_400_000 # Giảm trừ gia cảnh cho mỗi người phụ thuộc

  PERSONAL_INCOME_TAX_RATES = {
    5_000_000 => 0.05,
    10_000_000 => 0.1,
    18_000_000 => 0.15,
    32_000_000 => 0.2,
    52_000_000 => 0.25,
    80_000_000 => 0.3,
    Float::INFINITY => 0.35
  }

  def initialize(gross_amount, dependent_count: 0, tax_area: 1, insurance_type: :based_on_gross, insurance_rate: nil)
    @gross_amount = gross_amount
    @dependent_count = dependent_count
    @tax_area = tax_area
    @insurance_type = insurance_type
    @insurance_rate = insurance_rate
  end

  def perform
    insurance_base = insurance_type == :based_on_gross ? [gross_amount, 46_800_000].min : insurance_rate.to_i
    social_insurance_amount = (insurance_base * 0.08).to_i
    health_insurance_amount = (insurance_base * 0.015).to_i
    unemployment_insurance_amount = (insurance_base * 0.01).to_i

    before_tax_amount = gross_amount - social_insurance_amount - health_insurance_amount - unemployment_insurance_amount

    apply_tax_amount = before_tax_amount - PERSONAL_FAMILY_DEDUCTION - (dependent_count * DEPENDENT_DEDUCTION)
    apply_tax_amount = 0 if apply_tax_amount < 0

    total_income_tax = calculate_personal_income_tax(apply_tax_amount)

    hashable_information = {
      social_insurance_amount: social_insurance_amount,
      health_insurance_amount: health_insurance_amount,
      unemployment_insurance_amount: unemployment_insurance_amount,
      before_tax_amount: before_tax_amount,
      personal_income_tax_details: total_income_tax
    }

    hashable_information.to_o
  end

  private def calculate_personal_income_tax(apply_tax_amount)
    before_tax_limit = 0
    personal_income_tax_details = PERSONAL_INCOME_TAX_RATES.map do |limit, rate|
      tax_calculation_count = [apply_tax_amount - before_tax_limit, limit - before_tax_limit].min
      tax = ([tax_calculation_count, 0].max * rate).round.to_i

      result = [before_tax_limit..limit, tax]
      before_tax_limit = limit

      result
    end

    personal_income_tax_details.to_h
  end

  private def get_tax_from_area(area)
    raise ArgumentError, "invalid area number: #{area}" unless area.in?(1..4)

    DEDUCTION_FROM_AREAS[area - 1]
  end
end
