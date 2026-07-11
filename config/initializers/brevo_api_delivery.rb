require Rails.root.join("lib/brevo_api_delivery_method")

if ENV["BREVO_API_KEY"].present? && !Rails.env.test?
  ActionMailer::Base.add_delivery_method(
    :brevo_api,
    BrevoApiDeliveryMethod,
    api_key: ENV.fetch("BREVO_API_KEY"),
    sender_email: ENV.fetch("MAILER_SENDER", "mizosocietyjapan@gmail.com"),
    sender_name: ENV.fetch("MAILER_SENDER_NAME", "Mizo Society of Japan"),
    open_timeout: ENV.fetch("BREVO_API_OPEN_TIMEOUT", 5).to_i,
    read_timeout: ENV.fetch("BREVO_API_READ_TIMEOUT", 15).to_i
  )
  ActionMailer::Base.delivery_method = :brevo_api
end
