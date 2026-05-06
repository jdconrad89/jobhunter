# frozen_string_literal: true

module JobPosts
  class Filter
    def self.call(filter_params)
      new(filter_params).call
    end

    # filter_params: Hash or permitted ActionController::Parameters (already allowlisted by the controller).
    def initialize(filter_params)
      @params = (filter_params&.to_h || {}).with_indifferent_access
    end

    def call
      scope = JobPost.includes(:company).order(created_at: :desc)

      if (company = @params[:company].to_s.strip).present?
        escaped_company = ActiveRecord::Base.sanitize_sql_like(company)
        scope = scope.joins(:company).where("companies.name ILIKE ?", "%#{escaped_company}%")
      end

      case @params[:remote]
      when "true"
        scope = scope.remote_only
      when "false"
        scope = scope.on_site_only
      end

      case @params[:position_type]
      when "contract"
        scope = scope.contract_only
      when "full_time"
        scope = scope.full_time_only
      end

      if @params[:pay_range].present?
        parts = @params[:pay_range].split("_")
        pay_min = parts[0].presence&.to_i if parts[0].present?
        pay_max = parts[1].presence&.to_i if parts[1].present?
        scope = scope.filter_by_pay_range(pay_min, pay_max) if pay_min.present? || pay_max.present?
      end

      if @params[:experience_range].present?
        parts = @params[:experience_range].split("_")
        exp_min = parts[0].presence&.to_i if parts[0].present?
        exp_max = parts[1].presence&.to_i if parts[1].present?
        scope = scope.filter_by_experience_range(exp_min, exp_max) if exp_min.present? || exp_max.present?
      end

      scope
    end
  end
end
