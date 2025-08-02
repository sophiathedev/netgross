# frozen_string_literal: true

class TaxCalculatorController < ApplicationController
  def index
    @result = nil
  end

  def calculate
    Rails.logger.info "Params: \\#{params.inspect}"
    gross_amount_str = params[:gross_amount].to_s.gsub(/[^\d]/, '')
    @gross_amount = gross_amount_str.to_i
    Rails.logger.info "Parsed gross_amount: \\#{@gross_amount}"
    @dependent_count = params[:dependent_count].to_i
    @tax_area = params[:tax_area].to_i
    @insurance_type = params[:insurance_type]&.to_sym || :based_on_gross
    @insurance_rate = params[:insurance_rate]

    if @gross_amount > 0
      service = ConvertGrossToNetService.new(
        @gross_amount,
        dependent_count: @dependent_count,
        tax_area: @tax_area,
        insurance_type: @insurance_type,
        insurance_rate: @insurance_rate
      )

      @result = service.perform
    else
      @result = nil
      flash.now[:error] = 'Vui lòng nhập thu nhập hợp lệ'
    end

    respond_to do |format|
      format.turbo_stream do
        Rails.logger.info "Rendering turbo_stream for calculate action with result: #{@result.present?}"
      end
      format.html { render :index }
    end
  end
end
