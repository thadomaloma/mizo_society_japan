require "uri"

module Admin
  class SettingsController < ApplicationController
    SETTING_DEFINITIONS = [
      {
        key: "organization_name",
        label: "Organization Name",
        description: "Shown in portal headers, public notices, and future emails.",
        type: :text,
        group: "Organization",
        placeholder: "Mizo Society of Japan",
        default: "Mizo Society of Japan"
      },
      {
        key: "contact_email",
        label: "Contact Email",
        description: "Main reply address for member support and future mailers.",
        type: :email,
        group: "Organization",
        placeholder: "admin@example.com"
      },
      {
        key: "contact_phone",
        label: "Contact Phone",
        description: "Primary society contact number for member-facing pages.",
        type: :tel,
        group: "Organization",
        placeholder: "09012345678"
      },
      {
        key: "portal_notice",
        label: "Portal Notice",
        description: "Short admin-controlled notice for future dashboard banners.",
        type: :textarea,
        group: "Communication",
        placeholder: "Write a short announcement for members."
      },
      {
        key: "maintenance_mode",
        label: "Maintenance Mode",
        description: "Shows a maintenance page to members while super admins keep access.",
        type: :boolean,
        group: "System",
        default: "0"
      }
    ].freeze
    SETTING_KEYS = SETTING_DEFINITIONS.pluck(:key).freeze

    def show
      authorize AppSetting
      @setting_sections = setting_sections
    end

    def update
      authorize AppSetting

      normalized_settings = settings_params.each_with_object({}) do |(key, value), settings|
        settings[key] = normalized_setting_value(key, value)
      end
      @settings_errors = settings_errors_for(normalized_settings)
      if @settings_errors.any?
        @setting_sections = setting_sections(normalized_settings)
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
          action: "settings_updated",
          metadata: { changed_keys: changed_keys },
          request: request
        )
      end

      redirect_to admin_settings_path, notice: changed_keys.any? ? "Settings were updated." : "No settings were changed."
    end

    private

    def setting_sections(overrides = {})
      SETTING_DEFINITIONS.group_by { |definition| definition[:group] }.transform_values do |definitions|
        definitions.map do |definition|
          value = overrides.fetch(definition[:key]) { AppSetting.get(definition[:key], definition[:default]) }
          definition.merge(value: value)
        end
      end
    end

    def settings_params
      params.require(:settings).permit(*SETTING_KEYS).to_h
    end

    def normalized_setting_value(key, value)
      definition = SETTING_DEFINITIONS.find { |setting| setting[:key] == key }
      return AppSetting::BOOLEAN.cast(value) ? "1" : "0" if definition&.fetch(:type) == :boolean

      value.to_s.strip
    end

    def settings_errors_for(settings)
      errors = []
      errors << "Organization name cannot be blank." if settings["organization_name"].blank?
      errors << "Contact email is not valid." if settings["contact_email"].present? && !settings["contact_email"].match?(URI::MailTo::EMAIL_REGEXP)
      errors << "Contact phone must contain a valid phone number." if settings["contact_phone"].present? && !settings["contact_phone"].match?(%r{\A\+?[0-9][0-9\s-]{7,}\z})
      errors << "Portal notice must be 280 characters or fewer." if settings["portal_notice"].to_s.length > 280
      errors
    end
  end
end
