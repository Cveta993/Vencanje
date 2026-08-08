admin_email = ENV.fetch("ADMIN_EMAIL", "admin@example.com")
admin_password = ENV["ADMIN_PASSWORD"].presence

if Rails.env.production? && admin_password.blank?
  raise "Set ADMIN_PASSWORD before running seeds in production"
end

admin_password ||= "promeni-me-odmah"

admin = User.find_or_initialize_by(email_address: admin_email.downcase)
admin.password = admin_password
admin.password_confirmation = admin_password
admin.save!

if Rails.env.development?
  invitation = Invitation.find_or_create_by!(first_name: "Demo", last_name: "Gost") do |record|
    record.note = "Primer pozivnice za lokalni razvoj"
  end

  puts "Admin: #{admin.email_address} / #{admin_password}"
  puts "Primer pozivnice: http://localhost:3000/pozivnica/#{invitation.access_token}"
end
