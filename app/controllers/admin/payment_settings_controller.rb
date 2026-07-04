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
        description: "For ゆうちょ銀行 transfers from other banks, this is the store name members should enter, for example 〇一八.",
        type: :text,
        placeholder: "〇一八"
      },
      {
        key: "bank_account_number",
        label: "Bank Account Number",
        description: "Account type and number members should transfer to, for example 普通 1234567.",
        type: :text,
        placeholder: "普通 1234567"
      },
      {
        key: "yucho_symbol",
        label: "Yuucho Symbol (記号)",
        description: "Use this for ゆうちょ銀行 to ゆうちょ銀行 transfers when the app or ATM asks for 記号.",
        type: :text,
        placeholder: "12345"
      },
      {
        key: "yucho_number",
        label: "Yuucho Number (番号)",
        description: "Use this for ゆうちょ銀行 to ゆうちょ銀行 transfers when the app or ATM asks for 番号.",
        type: :text,
        placeholder: "12345671"
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
        value = overrides.fetch(definition[:key]) { bank_setting_value(definition[:key]) }
        definition.merge(value: value)
      end
    end

    def bank_setting_value(key)
      return yucho_symbol_value if key == "yucho_symbol"
      return yucho_number_value if key == "yucho_number"

      AppSetting.get(key)
    end

    def yucho_symbol_value
      explicit_yucho_symbol.presence || inferred_yucho_parts.first
    end

    def yucho_number_value
      explicit_yucho_number.presence || inferred_yucho_parts.second
    end

    def explicit_yucho_symbol
      symbol = AppSetting.get("yucho_symbol").to_s.strip
      return symbol if symbol.blank?

      parts = symbol.scan(/\d+/)
      parts.size >= 2 ? parts.first : symbol
    end

    def explicit_yucho_number
      number = AppSetting.get("yucho_number").to_s.strip
      return number if number.blank?

      parts = number.scan(/\d+/)
      parts.size >= 2 ? parts.second : number
    end

    def inferred_yucho_parts
      @inferred_yucho_parts ||= begin
        symbol = AppSetting.get("yucho_symbol").to_s
        number = AppSetting.get("yucho_number").to_s
        legacy = AppSetting.get("yucho_symbol_number").to_s
        source = [ symbol, number, legacy ].find { |value| value.scan(/\d+/).size >= 2 }.presence || legacy
        source.scan(/\d+/).first(2)
      end
    end

    def payment_settings_params
      params.require(:settings).permit(*BANK_SETTING_KEYS).to_h
    end

    def settings_errors_for(settings)
      []
    end
  end
end
