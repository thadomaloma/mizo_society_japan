class BankTransferDetails
  def self.call
    new.to_h
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
      bank_name: AppSetting.get("bank_name", "Please set bank name"),
      branch_name: AppSetting.get("bank_branch_name", "Please set branch / store name"),
      account_number: AppSetting.get("bank_account_number", "Please set account number"),
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
