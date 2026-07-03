# Keep OAuth callback URLs stable behind Railway's HTTPS proxy.
OmniAuth.config.full_host = lambda do |env|
  if Rails.env.production? && ENV["APP_HOST"].present?
    "#{ENV.fetch('APP_PROTOCOL', 'https')}://#{ENV.fetch('APP_HOST')}"
  else
    request = Rack::Request.new(env)
    "#{request.scheme}://#{request.host_with_port}"
  end
end
