# app/models/donation.rb
class Donation < ApplicationRecord
  belongs_to :user
  
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :donation_date, presence: true
  validates :platform, presence: true
  validates :transaction_id, uniqueness: { allow_blank: true }
  validates :currency, presence: true
  
  # Callbacks
  after_create :update_user_lifetime_donations
  after_update :update_user_lifetime_donations, if: :saved_change_to_amount?
  after_destroy :update_user_lifetime_donations
  
  # Scopes
  scope :by_platform, ->(platform) { where(platform: platform) }
  scope :by_currency, ->(currency) { where(currency: currency) }
  scope :by_date_range, ->(start_date, end_date) { where(donation_date: start_date..end_date) }
  scope :recent, -> { order(donation_date: :desc) }
  scope :this_month, -> { where(donation_date: Time.current.beginning_of_month..Time.current.end_of_month) }
  scope :this_year, -> { where(donation_date: Time.current.beginning_of_year..Time.current.end_of_year) }
  scope :today, -> { where(donation_date: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :with_transaction_id, -> { where.not(transaction_id: [nil, '']) }
  scope :imported, -> { where.not(platform: 'Manual') }
  scope :manual, -> { where(platform: 'Manual') }
  
  def formatted_amount(include_currency: true)
    symbol = currency_symbol
    if include_currency && currency != 'USD'
      "#{symbol}#{amount.to_f.round(2)} #{currency}"
    else
      "#{symbol}#{amount.to_f.round(2)}"
    end
  end
  
  def formatted_date
    donation_date.strftime('%B %d, %Y')
  end
  
  def formatted_datetime
    donation_date.strftime('%B %d, %Y at %I:%M %p')
  end
  
  def currency_symbol
    case currency&.upcase
    when 'USD' then '$'
    when 'EUR' then '€'
    when 'GBP' then '£'
    when 'JPY' then '¥'
    when 'CAD' then 'C$'
    when 'AUD' then 'A$'
    else '$'
    end
  end
  
  def is_recent?
    donation_date > 30.days.ago
  end
  
  def is_large_donation?(threshold = 100.0)
    amount >= threshold
  end
  
  # Check if this donation might be a duplicate of another
  def potential_duplicate?
    return false unless user_id && amount && donation_date
    
    date_range = donation_date.beginning_of_day..donation_date.end_of_day
    
    Donation.where(
      user_id: user_id,
      amount: amount,
      donation_date: date_range
    ).where.not(id: id).exists?
  end
  
  # Find potential duplicates
  def find_potential_duplicates
    return Donation.none unless user_id && amount && donation_date
    
    date_range = donation_date.beginning_of_day..donation_date.end_of_day
    
    Donation.where(
      user_id: user_id,
      amount: amount,
      donation_date: date_range
    ).where.not(id: id)
  end
  
  # Class methods for reporting
  def self.total_amount_for_period(start_date, end_date)
    by_date_range(start_date, end_date).sum(:amount)
  end
  
  def self.count_for_period(start_date, end_date)
    by_date_range(start_date, end_date).count
  end
  
  def self.average_donation_for_period(start_date, end_date)
    by_date_range(start_date, end_date).average(:amount)&.round(2) || 0
  end
  
  def self.by_platform_stats(start_date = nil, end_date = nil)
    scope = start_date && end_date ? by_date_range(start_date, end_date) : all
    
    scope.group(:platform).group(:currency).calculate(:sum, :amount)
  end
  
  def self.monthly_totals(year = Time.current.year)
    by_date_range(
      Date.new(year, 1, 1).beginning_of_day,
      Date.new(year, 12, 31).end_of_day
    ).group_by_month(:donation_date).sum(:amount)
  end
  
  def self.top_donors(limit = 10, start_date = nil, end_date = nil)
    scope = start_date && end_date ? by_date_range(start_date, end_date) : all
    
    scope.joins(:user)
         .group('users.id', 'users.username', 'users.email')
         .sum(:amount)
         .sort_by { |_, total| -total }
         .first(limit)
         .map do |user_data, total|
           {
             user_id: user_data[0],
             username: user_data[1],
             email: user_data[2],
             total_donated: total
           }
         end
  end
  
  def self.recent_large_donations(threshold = 100.0, limit = 10)
    where('amount >= ?', threshold)
      .includes(:user)
      .recent
      .limit(limit)
  end
  
  # Find duplicates across the entire database
  def self.find_all_potential_duplicates
    select('user_id, amount, DATE(donation_date) as donation_day, COUNT(*) as duplicate_count')
      .group('user_id, amount, DATE(donation_date)')
      .having('COUNT(*) > 1')
      .includes(:user)
  end
  
  private
  
  def update_user_lifetime_donations
    return unless user
    
    new_total = user.donations.sum(:amount)
    latest_donation = user.donations.maximum(:donation_date)
    
    user.update_columns(
      lifetime_donations: new_total,
      last_donation_date: latest_donation
    )
  end
end