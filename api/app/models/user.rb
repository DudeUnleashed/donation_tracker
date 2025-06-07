# app/models/user.rb
class User < ApplicationRecord
  has_many :donations, dependent: :destroy
  
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { case_sensitive: false }
  validates :username, presence: true
  validates :current_status, inclusion: { in: %w[active inactive suspended] }
  
  # Callbacks
  before_validation :normalize_email
  before_validation :set_default_username, if: -> { username.blank? && email.present? }
  before_save :update_current_status
  
  # Scopes
  scope :active, -> { where(current_status: 'active') }
  scope :inactive, -> { where(current_status: 'inactive') }
  scope :suspended, -> { where(current_status: 'suspended') }
  scope :with_donations, -> { joins(:donations).distinct }
  scope :without_donations, -> { left_joins(:donations).where(donations: { id: nil }) }
  scope :recent_donors, ->(days = 30) { joins(:donations).where(donations: { donation_date: days.days.ago..Time.current }).distinct }
  scope :top_donors, ->(limit = 10) { order(lifetime_donations: :desc).limit(limit) }
  scope :by_platform, ->(platform) { joins(:donations).where(donations: { platform: platform }).distinct }
  scope :search, ->(query) { where('username ILIKE ? OR email ILIKE ?', "%#{query}%", "%#{query}%") }
  
  def full_identifier
    if username.present? && username != email_username
      "#{username} (#{email})"
    else
      email
    end
  end
  
  def display_name
    username.presence || email_username
  end
  
  def email_username
    email&.split('@')&.first
  end
  
  def total_donations_count
    donations.count
  end
  
  def total_donated(currency: nil)
    scope = donations
    scope = scope.by_currency(currency) if currency
    scope.sum(:amount)
  end
  
  def average_donation_amount
    return 0 if donations.empty?
    (lifetime_donations / donations.count).round(2)
  end
  
  def first_donation_date
    donations.minimum(:donation_date)
  end
  
  def days_since_last_donation
    return nil unless last_donation_date
    (Time.current.to_date - last_donation_date.to_date).to_i
  end
  
  def is_recent_donor?(days = 30)
    last_donation_date && last_donation_date > days.days.ago
  end
  
  def is_major_donor?(threshold = 500.0)
    lifetime_donations >= threshold
  end
  
  def donation_frequency
    return 'Never' if donations.empty?
    return 'Once' if donations.count == 1
    
    first_donation = first_donation_date
    return 'Recent' unless first_donation
    
    days_active = (Time.current.to_date - first_donation.to_date).to_i
    return 'Recent' if days_active < 30
    
    donations_per_month = (donations.count.to_f / (days_active / 30.0))
    
    case donations_per_month
    when 0...0.5 then 'Rare'
    when 0.5...1.5 then 'Monthly'
    when 1.5...4 then 'Weekly'
    else 'Frequent'
    end
  end
  
  def platforms_used
    donations.distinct.pluck(:platform).compact
  end
  
  def preferred_platform
    donations.group(:platform).count.max_by { |_, count| count }&.first
  end
  
  def currencies_used
    donations.distinct.pluck(:currency).compact
  end
  
  def recent_donations(limit = 5)
    donations.recent.limit(limit)
  end
  
  def largest_donation
    donations.maximum(:amount) || 0
  end
  
  def donations_this_year
    donations.this_year
  end
  
  def donations_this_month
    donations.this_month
  end
  
  def monthly_donation_total(year = Time.current.year, month = Time.current.month)
    start_date = Date.new(year, month, 1).beginning_of_day
    end_date = start_date.end_of_month.end_of_day
    donations.by_date_range(start_date, end_date).sum(:amount)
  end
  
  def has_potential_duplicates?
    donations.any?(&:potential_duplicate?)
  end
  
  def potential_duplicate_donations
    donation_ids = []
    donations.each do |donation|
      if donation.potential_duplicate?
        donation_ids += donation.find_potential_duplicates.pluck(:id)
        donation_ids << donation.id
      end
    end
    Donation.where(id: donation_ids.uniq)
  end
  
  # Class methods
  def self.find_or_create_by_email(email, username: nil)
    email = email.to_s.downcase.strip
    user = find_by(email: email)
    
    return user if user
    
    create!(
      email: email,
      username: username || email.split('@').first
    )
  end
  
  def self.merge_users(primary_user, duplicate_user)
    return false if primary_user == duplicate_user
    
    # Move all donations to primary user
    duplicate_user.donations.update_all(user_id: primary_user.id)
    
    # Update primary user's totals
    primary_user.reload
    primary_user.send(:update_user_totals)
    
    # Delete duplicate user
    duplicate_user.destroy
    
    true
  end
  
  def self.inactive_users(days = 90)
    where('last_donation_date < ? OR last_donation_date IS NULL', days.days.ago)
  end
  
  def self.stats_summary
    {
      total_users: count,
      active_users: active.count,
      users_with_donations: with_donations.count,
      users_without_donations: without_donations.count,
      recent_donors: recent_donors.count,
      total_lifetime_donations: sum(:lifetime_donations),
      average_lifetime_donation: average(:lifetime_donations)&.round(2) || 0
    }
  end
  
  private
  
  def normalize_email
    self.email = email.to_s.downcase.strip if email
  end
  
  def set_default_username
    self.username = email.split('@').first if email
  end
  
  def update_current_status
    if last_donation_date
      days_since_last = (Time.current.to_date - last_donation_date.to_date).to_i
      
      self.current_status = case days_since_last
                           when 0..90 then 'active'
                           when 91..365 then 'inactive'  
                           else current_status # Don't auto-change to suspended
                           end
    end
  end
  
  def update_user_totals
    self.lifetime_donations = donations.sum(:amount)
    self.last_donation_date = donations.maximum(:donation_date)
    save!
  end
end