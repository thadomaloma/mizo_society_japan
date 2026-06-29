require "uri"

module Admin
  class PaymentSettingsController < ApplicationController
    BANK_SETTING_DEFINITIONS = [
      {
        key: "bank_account_name",
        label: "Bank Account Name",
        description: "Shown to members before they submit a bank transfer.",
        type: :text,
        placeholder: "Mizo Society of Japan"
      },
      {
        key: "bank_name",
        label: "Bank Name",
        description: "Bank name for member transfer instructions.",
        type: :text,
        placeholder: "MUFG Bank"
      },
      {
        key: "bank_branch_name",
        label: "Store Name (店名)",
        description: "For ゆうちょ銀行 transfers from other banks, this is the store name, for example 〇一八.",
        type: :text,
        placeholder: "〇一八"
      },
      {
        key: "bank_branch_code",
        label: "Store Number (店番)",
        description: "Some bank apps ask for the store number instead of the store name, for example 018.",
        type: :text,
        placeholder: "018"
      },
      {
        key: "bank_account_number",
        label: "Bank Account Number",
        description: "Account type and number members should transfer to, for example 普通 1234567.",
        type: :text,
        placeholder: "普通 1234567"
      },
      {
        key: "yucho_symbol_number",
        label: "Yuucho Symbol / Number (optional)",
        description: "Only needed for ゆうちょ-to-ゆうちょ transfers. Leave blank if members should use store name, store number, and account number.",
        type: :text,
        placeholder: "記号 12345 / 番号 12345671"
      },
      {
        key: "bank_qr_code_url",
        label: "Bank QR Code URL",
        description: "Optional image URL for bank transfer instructions.",
        type: :url,
        placeholder: "https://example.com/bank-qr.png"
      }
    ].freeze
    BANK_SETTING_KEYS = BANK_SETTING_DEFINITIONS.pluck(:key).freeze

    def show
      authorize AppSetting, :payment?
      @bank_settings = bank_settings
    end

    def update
      authorize AppSetting, :update_payment?

      normalized_settings = payment_settings_params.each_with_object({}) do |(key, value), settings|
        settings[key] = value.to_s.strip
      end
      @settings_errors = settings_errors_for(normalized_settings)
      if @settings_errors.any?
        @bank_settings = bank_settings(normalized_settings)
        render :show, status: :unprocessable_entity
        return
      end

      changed_keys = []
      normalized_settings.each do |key, value|
        previous_value = AppSetting.get(key)
        next if previous_value.to_s == value.to_s

        AppSetting.set(key, value)
        changed_keys << key
      end

      if changed_keys.any?
        AuditLogger.call(
          user: current_user,
          action: "payment_bank_details_updated",
          metadata: { changed_keys: changed_keys },
          request: request
        )
      end

      redirect_to admin_payment_settings_path, notice: changed_keys.any? ? "Bank details were updated." : "No bank details were changed."
    end

    private

    def bank_settings(overrides = {})
      BANK_SETTING_DEFINITIONS.map do |definition|
        value = overrides.fetch(definition[:key]) { AppSetting.get(definition[:key]) }
        definition.merge(value: value)
      end
    end

    def payment_settings_params
      params.require(:settings).permit(*BANK_SETTING_KEYS).to_h
    end

    def settings_errors_for(settings)
      errors = []
      if settings["bank_qr_code_url"].present? && !settings["bank_qr_code_url"].match?(URI::DEFAULT_PARSER.make_regexp(%w[http https]))
        errors << "Bank QR Code URL is not valid."
      end
      errors
    end
  end
end
