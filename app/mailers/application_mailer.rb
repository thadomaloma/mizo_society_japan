class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_SENDER", "no-reply@mizosocietyjapan.org")
  layout "mailer"
end
