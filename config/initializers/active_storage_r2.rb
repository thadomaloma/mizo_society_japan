# Fail fast with a clear message when production is configured to use
# Cloudflare R2 but the required Railway variables are missing.
if Rails.env.production? && ENV["ACTIVE_STORAGE_SERVICE"].to_s == "cloudflare_r2"
  required_r2_env = %w[
    CLOUDFLARE_R2_ACCESS_KEY_ID
    CLOUDFLARE_R2_SECRET_ACCESS_KEY
    CLOUDFLARE_R2_BUCKET
    CLOUDFLARE_R2_ENDPOINT
  ]
  missing_r2_env = required_r2_env.select { |key| ENV[key].blank? }

  if missing_r2_env.any?
    raise "Cloudflare R2 is enabled, but these env vars are missing: #{missing_r2_env.join(', ')}"
  end
end
