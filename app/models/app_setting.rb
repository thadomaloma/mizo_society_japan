class AppSetting < ApplicationRecord
  BOOLEAN = ActiveModel::Type::Boolean.new

  validates :key, presence: true, uniqueness: { case_sensitive: false }

  scope :ordered, -> { order(:key) }

  def self.get(key, default = nil)
    find_by(key: key.to_s)&.value.presence || default
  end

  def self.enabled?(key, default = false)
    BOOLEAN.cast(get(key, default))
  end

  def self.set(key, value)
    setting = find_or_initialize_by(key: key.to_s)
    setting.update!(value: value)
    setting
  end
end
