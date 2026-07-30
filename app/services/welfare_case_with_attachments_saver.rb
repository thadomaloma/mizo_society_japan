class WelfareCaseWithAttachmentsSaver
  def self.call(welfare_case:, attributes:, files:, uploaded_by:)
    new(
      welfare_case: welfare_case,
      attributes: attributes,
      files: files,
      uploaded_by: uploaded_by
    ).call
  end

  def initialize(welfare_case:, attributes:, files:, uploaded_by:)
    @welfare_case = welfare_case
    @attributes = attributes
    @files = Array(files).compact_blank
    @uploaded_by = uploaded_by
  end

  def call
    WelfareCase.transaction do
      welfare_case.update!(attributes)
      files.each { |file| save_attachment!(file) }
    end

    true
  rescue ActiveRecord::RecordInvalid => error
    copy_attachment_errors(error.record) unless error.record.equal?(welfare_case)
    false
  end

  private

  attr_reader :welfare_case, :attributes, :files, :uploaded_by

  def save_attachment!(file)
    attachment = welfare_case.welfare_attachments.build(uploaded_by: uploaded_by)
    attachment.file.attach(file)
    attachment.save!
  end

  def copy_attachment_errors(record)
    record.errors.full_messages.each do |message|
      welfare_case.errors.add(:files, message)
    end
  end
end
