class AppSetting < ApplicationRecord
  BOOLEAN = ActiveModel::Type::Boolean.new

  after_commit :clear_cached_value

  validates :key, presence: true, uniqueness: { case_sensitive: false }

  scope :ordered, -> { order(:key) }

  def self.get(key, default = nil)
    normalized_key = key.to_s
    value = Rails.cache.fetch(cache_key_for(normalized_key), expires_in: 12.hours) do
      find_by(key: normalized_key)&.value
    end

    value.presence || default
  end

  def self.enabled?(key, default = false)
    BOOLEAN.cast(get(key, default))
  end

  def self.set(key, value)
    setting = find_or_initialize_by(key: key.to_s)
    setting.update!(value: value)
    setting
  end

  def self.cache_key_for(key)
    "app_settings/#{key}"
  end

  private

  def clear_cached_value
    Rails.cache.delete(self.class.cache_key_for(key))
  end
end
