require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on durable object storage in production.
  # Use :cloudflare_r2 on Railway by setting ACTIVE_STORAGE_SERVICE=cloudflare_r2.
  config.active_storage.service = ENV.fetch("ACTIVE_STORAGE_SERVICE", "local").to_sym

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Keep production caching in-process for single-container Railway deploys.
  # This avoids requiring the solid_cache_entries table on every database reset
  # or region move, while still caching settings and dashboard aggregates.
  config.cache_store = :memory_store, { size: ENV.fetch("RAILS_CACHE_SIZE_MB", 64).to_i * 1024 * 1024 }

  # Keep production jobs in-process unless a dedicated Solid Queue database has
  # been provisioned. This avoids upload failures when Active Storage enqueues
  # purge jobs on hosts without the solid_queue_* tables.
  config.active_job.queue_adapter = ENV.fetch("ACTIVE_JOB_QUEUE_ADAPTER", "async").to_sym
  config.solid_queue.connects_to = { database: { writing: :queue } } if config.active_job.queue_adapter == :solid_queue

  # Raise delivery errors in production so password-reset mail failures are
  # visible in the host logs instead of silently disappearing.
  config.action_mailer.raise_delivery_errors = true

  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST", "example.com"),
    protocol: ENV.fetch("APP_PROTOCOL", "https")
  }

  smtp_username = ENV["BREVO_LOGIN"].presence || ENV["SMTP_USERNAME"].presence
  smtp_password = ENV["BREVO_SMTP_KEY"].presence || ENV["SMTP_PASSWORD"].presence

  if ENV["BREVO_API_KEY"].blank? && ENV["SMTP_ADDRESS"].present? && smtp_username.present? && smtp_password.present?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV.fetch("SMTP_ADDRESS"),
      port: ENV.fetch("SMTP_PORT", 587).to_i,
      domain: ENV.fetch("SMTP_DOMAIN", ENV.fetch("APP_HOST", "mizosocietyjapan.org")),
      user_name: smtp_username,
      password: smtp_password,
      authentication: ENV.fetch("SMTP_AUTHENTICATION", "plain").to_sym,
      enable_starttls_auto: ActiveModel::Type::Boolean.new.cast(ENV.fetch("SMTP_ENABLE_STARTTLS_AUTO", "true")),
      openssl_verify_mode: ENV.fetch("SMTP_OPENSSL_VERIFY_MODE", "peer")
    }.compact
  end

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
