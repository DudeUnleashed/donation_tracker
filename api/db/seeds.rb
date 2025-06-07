# frozen_string_literal: true

# Create test website users (admin/viewer)
WebsiteUser.create!(
  username: 'testadmin',
  email: 'admin@test.com',
  password: 'password123',
  role: 'admin'
)

WebsiteUser.create!(
  username: 'testviewer',
  email: 'viewer@test.com',
  password: 'password123',
  role: 'viewer'
)

# Create some test donors
# 5.times do |i|
  # user = User.create!(
    # username: "donor#{i}",
    # email: "donor#{i}@example.com",
    # platform_id: "PLAT#{i}"
  # )
  
  # Create some donations for each user
  # 3.times do |j|
    # user.donations.create!(
      # amount: rand(10.0..100.0).round(2),
      # platform: ['PayPal', 'BuyMeACoffee'].sample,
      # donation_date: rand(1..30).days.ago
    # )
  # end
  
  # user.update_lifetime_donations
# end

puts "Created website logins."
