class BankTransferDetails
  def self.call
    new.to_h
  end

  def self.configured?
    details = call
    account_ready = AppSetting.get("bank_account_name").present? && details[:bank_name].present?
    another_bank_ready = details[:branch_name].present? && details[:account_number].present?
    yucho_ready = details[:yucho_symbol].present? && details[:yucho_number].present?

    account_ready && (another_bank_ready || yucho_ready)
  end

  def self.yucho_parts(symbol:, number:, legacy: nil)
    new.yucho_parts(symbol:, number:, legacy:)
  end

  def to_h
    symbol, number = yucho_parts(
      symbol: AppSetting.get("yucho_symbol"),
      number: AppSetting.get("yucho_number"),
      legacy: [
        AppSetting.get("yucho_symbol_number"),
        AppSetting.get("bank_account_number")
      ]
    )

    {
      account_name: AppSetting.get("bank_account_name", "Mizo Society of Japan"),
      bank_name: AppSetting.get("bank_name"),
      branch_name: AppSetting.get("bank_branch_name"),
      account_number: AppSetting.get("bank_account_number"),
      yucho_symbol: symbol,
      yucho_number: number
    }
  end

  def yucho_parts(symbol:, number:, legacy: nil)
    symbol = normalize_digits(symbol)
    number = normalize_digits(number)
    legacy_values = Array(legacy).map { |value| normalize_digits(value) }

    [ symbol, number, *legacy_values ].each do |value|
      pair = split_pair(value)
      return pair if pair.present?
    end

    [ symbol.presence, number.presence ]
  end

  private

  def normalize_digits(value)
    value.to_s.tr("０-９", "0-9").strip
  end

  def split_pair(value)
    parts = value.to_s.scan(/\d+/)
    return if parts.size < 2

    [ parts.first, parts.second ]
  end
end
