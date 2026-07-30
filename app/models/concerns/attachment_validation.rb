module AttachmentValidation
  private

  def validate_attachment_upload(attachment, attribute:, content_types:, max_size:)
    attachment_blobs(attachment).each do |blob|
      if content_types.present? && !blob.content_type.in?(content_types)
        errors.add(attribute, "has an unsupported file type")
      end

      if blob.byte_size > max_size
        errors.add(attribute, "must be smaller than #{ActiveSupport::NumberHelper.number_to_human_size(max_size)}")
      end
    end
  end

  def attachment_blobs(attachment)
    if attachment.respond_to?(:attachments)
      attachment.attachments.map(&:blob)
    elsif attachment.attached?
      [ attachment.blob ]
    else
      []
    end
  end
end
