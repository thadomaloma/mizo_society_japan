class AuditLogger
  def self.call(user:, action:, auditable: nil, metadata: {}, request: nil)
    new(user: user, action: action, auditable: auditable, metadata: metadata, request: request).call
  end

  def initialize(user:, action:, auditable: nil, metadata: {}, request: nil)
    @user = user
    @action = action
    @auditable = auditable
    @metadata = metadata
    @request = request
  end

  def call
    AuditLog.create!(
      user: user,
      action: action,
      auditable: auditable,
      metadata: normalized_metadata,
      ip_address: request&.remote_ip,
      user_agent: request&.user_agent
    )
  end

  private

  attr_reader :user, :action, :auditable, :metadata, :request

  def normalized_metadata
    JSON.parse(metadata.to_json)
  rescue JSON::ParserError, TypeError
    {}
  end
end
