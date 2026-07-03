default_password = ENV["SEED_SUPER_ADMIN_PASSWORD"].presence || ENV.fetch("SEED_USER_PASSWORD", "password123")
super_admin_email = ENV.fetch("SEED_SUPER_ADMIN_EMAIL", "president@msj.local")
super_admin_role = ENV.fetch("SEED_SUPER_ADMIN_ROLE", "president")
reset_password = ActiveModel::Type::Boolean.new.cast(ENV["RESET_SEED_SUPER_ADMIN_PASSWORD"])

unless super_admin_role.in?(User::SUPER_ADMIN_ROLES)
  raise ArgumentError, "SEED_SUPER_ADMIN_ROLE must be one of: #{User::SUPER_ADMIN_ROLES.join(', ')}"
end

super_admin = User.find_or_initialize_by(email: super_admin_email)
super_admin.assign_attributes(
  name: ENV.fetch("SEED_SUPER_ADMIN_NAME", User.role_label(super_admin_role)),
  role: super_admin_role,
  active: true
)
super_admin.password = default_password if super_admin.encrypted_password.blank? || reset_password
super_admin.save!

profile = super_admin.member_profile || super_admin.build_member_profile
profile.assign_attributes(
  full_name: super_admin.name,
  mobile_number: profile.mobile_number.presence || ENV.fetch("SEED_SUPER_ADMIN_MOBILE", "09024681357"),
  postal_code: profile.postal_code.presence || ENV.fetch("SEED_SUPER_ADMIN_POSTAL_CODE", "169-0075"),
  prefecture: profile.prefecture.presence || ENV.fetch("SEED_SUPER_ADMIN_PREFECTURE", "Tokyo"),
  city: profile.city.presence || ENV.fetch("SEED_SUPER_ADMIN_CITY", "Shinjuku"),
  address_line1: profile.address_line1.presence || ENV.fetch("SEED_SUPER_ADMIN_ADDRESS_LINE1", "1-1-1 Okubo"),
  joined_on: profile.joined_on || Date.current,
  status: :active
)
profile.save!

puts "Seeded one super admin: #{super_admin.email} (#{super_admin.role})"
