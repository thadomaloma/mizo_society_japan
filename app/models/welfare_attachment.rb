class WelfareAttachment < ApplicationRecord
  ALLOWED_CONTENT_TYPES = %w[
    application/pdf
    image/jpeg
    image/png
  ].freeze

  belongs_to :welfare_case
  belongs_to :uploaded_by, class_name: "User"
  has_one_attached :file

  validate :file_attached
  validate :file_content_type

  def file_size
    file.attached? ? file.blob.byte_size : 0
  end

  def file_extension
    return "" unless file.attached?

    file.filename.extension_without_delimiter.to_s.downcase
  end

  private

  def file_attached
    errors.add(:file, "must be attached") unless file.attached?
  end

  def file_content_type
    return unless file.attached?
    return if file.blob.content_type.in?(ALLOWED_CONTENT_TYPES)

    errors.add(:file, "must be a PDF, JPG, or PNG file")
  end
end
