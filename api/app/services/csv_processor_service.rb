require 'csv'

class CsvProcessorService
  attr_reader :csv_file, :provider, :current_user, :errors, :summary

  def initialize(csv_file, provider, current_user)
    @csv_file = csv_file
    @provider = provider.downcase
    @current_user = current_user
    @errors = []
    @summary = {
      total_rows: 0,
      processed_rows: 0,
      failed_rows: 0,
      new_users: 0,
      existing_users: 0,
      new_donations: 0,
      duplicate_donations: 0
    }
  end

  def process
    begin
      csv_content = csv_file.read.force_encoding('UTF-8')
      
      # Parse CSV with error handling
      csv_data = CSV.parse(csv_content, headers: true, header_converters: :symbol)
      
      @summary[:total_rows] = csv_data.length
      
      # Process each row
      csv_data.each_with_index do |row, index|
        process_row(row, index + 2) # +2 because CSV is 1-indexed and we skip header
      end

      # Log the import activity
      log_csv_import

      {
        success: @errors.empty?,
        total_rows: @summary[:total_rows],
        processed_rows: @summary[:processed_rows],
        failed_rows: @summary[:failed_rows],
        errors: @errors,
        summary: @summary
      }

    rescue CSV::MalformedCSVError => e
      @errors << "Invalid CSV format: #{e.message}"
      { success: false, errors: @errors, summary: @summary }
    rescue => e
      @errors << "Processing error: #{e.message}"
      { success: false, errors: @errors, summary: @summary }
    end
  end

  private

  def process_row(row, row_number)
    begin
      # Normalize the row data based on provider
      normalized_data = normalize_row_data(row)
      
      # Validate required fields
      unless validate_row_data(normalized_data, row_number)
        @summary[:failed_rows] += 1
        return
      end

      # Find or create user
      user = find_or_create_user(normalized_data)
      
      # Create donation if it doesn't already exist
      donation = create_donation_if_unique(user, normalized_data, row_number)
      
      @summary[:processed_rows] += 1

    rescue => e
      @errors << "Row #{row_number}: #{e.message}"
      @summary[:failed_rows] += 1
    end
  end

  def normalize_row_data(row)
    case @provider
    when 'paypal'
      normalize_paypal_data(row)
    when 'stripe'
      normalize_stripe_data(row)
    when 'square'
      normalize_square_data(row)
    when 'generic'
      normalize_generic_data(row)
    else
      normalize_generic_data(row)
    end
  end

  def normalize_key(key)
    key.to_s.downcase.strip.gsub(/\s+/, '_').to_sym
  end

  def normalize_paypal_data(row)
    normalized_row = row.to_h.transform_keys { |k| normalize_key(k) }

    {
      email: normalized_row[:from_email_address],
      username: normalized_row[:name] || extract_username_from_email(normalized_row[:from_email_address]),
      amount: parse_paypal_amount(normalized_row[:gross] || normalized_row[:amount]),
      donation_date: parse_paypal_date(normalized_row[:date], normalized_row[:time]),
      transaction_id: normalized_row[:transaction_id] || normalized_row[:txn_id],
      platform: 'PayPal',
      currency: normalized_row[:currency] || 'USD',
      type: normalized_row[:type]
    }
  end

  def normalize_stripe_data(row)
    {
      email: row[:customer_email] || row[:email],
      username: row[:customer_name] || extract_username_from_email(row[:customer_email] || row[:email]),
      amount: parse_amount(row[:amount]) / 100.0, # Stripe amounts are in cents
      donation_date: parse_date(row[:created] || row[:date]),
      transaction_id: row[:id] || row[:charge_id],
      platform: 'Stripe',
      currency: row[:currency] || 'usd'
    }
  end

  def normalize_square_data(row)
    {
      email: row[:buyer_email_address] || row[:email],
      username: row[:buyer_name] || extract_username_from_email(row[:buyer_email_address] || row[:email]),
      amount: parse_amount(row[:total_money] || row[:amount]),
      donation_date: parse_date(row[:created_at] || row[:date]),
      transaction_id: row[:id] || row[:transaction_id],
      platform: 'Square',
      currency: row[:currency] || 'USD'
    }
  end

  def normalize_generic_data(row)
    {
      email: row[:email],
      username: row[:username] || row[:name] || extract_username_from_email(row[:email]),
      amount: parse_amount(row[:amount]),
      donation_date: parse_date(row[:date] || row[:donation_date]),
      transaction_id: row[:transaction_id] || row[:id],
      platform: row[:platform] || 'Manual',
      currency: row[:currency] || 'USD'
    }
  end

  def validate_row_data(data, row_number)
    if @provider == 'paypal' && data[:type] != 'Subscription Payment'
            @errors << "Row #{row_number}: Skipping non-subscription payment (#{data[:type]})"
            return false
    end
    required_fields = [:email, :amount, :donation_date]
    missing_fields = required_fields.select { |field| data[field].blank? }
    
    if missing_fields.any?
      @errors << "Row #{row_number}: Missing required fields: #{missing_fields.join(', ')}"
      return false
    end

    # Validate email format
    unless data[:email].match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      @errors << "Row #{row_number}: Invalid email format: #{data[:email]}"
      return false
    end

    # Validate amount is positive
    if data[:amount] <= 0
      @errors << "Row #{row_number}: Amount must be positive: #{data[:amount]}"
      return false
    end

    true
  end

  def find_or_create_user(data)
    user = User.find_by(email: data[:email])
    
    if user
      @summary[:existing_users] += 1
      # Update username if it was blank and we have one
      if user.username.blank? && data[:username].present?
        user.update!(username: data[:username])
      end
    else
      user = User.create!(
        email: data[:email],
        username: data[:username] || extract_username_from_email(data[:email])
      )
      @summary[:new_users] += 1
    end
    
    user
  end

  def create_donation_if_unique(user, data, row_number)
    # Check for duplicate based on transaction_id or combination of user, amount, and date
    existing_donation = nil
    
    if data[:transaction_id].present?
      existing_donation = Donation.find_by(
        transaction_id: data[:transaction_id]
      )
    end
    
    # If no transaction_id match, check by user, amount, and date (within same day)
    unless existing_donation
      date_range = Date.parse(data[:donation_date].to_s).beginning_of_day..Date.parse(data[:donation_date].to_s).end_of_day
      existing_donation = user.donations.where(
        amount: data[:amount],
        donation_date: date_range
      ).first
    end

    if existing_donation
      @summary[:duplicate_donations] += 1
      Rails.logger.info "Row #{row_number}: Duplicate donation found, skipping"
      return existing_donation
    end

    donation = user.donations.create!(
      amount: data[:amount],
      donation_date: data[:donation_date],
      platform: data[:platform],
      transaction_id: data[:transaction_id],
      currency: data[:currency]
    )
    
    @summary[:new_donations] += 1
    donation
  end

  def extract_username_from_email(email)
    return nil if email.blank?
    email.split('@').first
  end

  def parse_amount(amount_str)
    return 0.0 if amount_str.blank?
    
    # Remove currency symbols and commas
    cleaned = amount_str.to_s.gsub(/[$,£€¥]/, '').strip
    
    # Handle negative amounts (refunds) - convert to positive
    cleaned = cleaned.gsub(/^\((.+)\)$/, '-\1')
    
    Float(cleaned).abs
  rescue ArgumentError
    0.0
  end

  def parse_paypal_amount(amount_str)
    return 0.0 if amount_str.blank?

    # Remove all thousands separators (dots or commas depending on locale)
    # Then replace decimal comma with decimal point
    cleaned = amount_str.to_s
              .gsub(/[.,](?=\d{3}\D|\d{3}$)/, '')  # Remove thousands separators
              .gsub(',', '.')                       # Replace decimal comma with point
              .gsub(/[^\d.-]/, '')                  # Remove any remaining non-numeric chars except - and .

    # Convert to float and take absolute value
    Float(cleaned).abs
  rescue ArgumentError
    0.0
  end

  def parse_date(date_str)
    return Time.current if date_str.blank?
    
    # Try different date formats
    date_formats = [
      '%Y-%m-%d %H:%M:%S',
      '%Y-%m-%d',
      '%m/%d/%Y %H:%M:%S',  
      '%m/%d/%Y',
      '%d/%m/%Y',
      '%Y-%m-%dT%H:%M:%S',
      '%Y-%m-%dT%H:%M:%SZ'
    ]
    
    date_formats.each do |format|
      begin
        return DateTime.strptime(date_str.to_s, format)
      rescue ArgumentError
        next
      end
    end
    
    # If all else fails, try Ruby's built-in parsing
    begin
      Time.parse(date_str.to_s)
    rescue ArgumentError
      Time.current
    end
  end

  
  def parse_paypal_date(date_str, time_str = nil)
    return Time.current if date_str.blank?
  
    # PayPal dates are typically DD/MM/YYYY
    date_parts = date_str.split('/')
    day = date_parts[0].to_i
    month = date_parts[1].to_i
    year = date_parts[2].to_i
  
    if time_str
      time_parts = time_str.split(':').map(&:to_i)
      hours = time_parts[0]
      minutes = time_parts[1]
      seconds = time_parts[2] || 0
    else
      hours = minutes = seconds = 0
    end
  
    Time.zone.local(year, month, day, hours, minutes, seconds)
  rescue
    Time.current
  end

  def log_csv_import
    AuditLog.create!(
      action: 'csv_import',
      user_id: @current_user.id,
      changes: {
        provider: @provider,
        summary: @summary,
        filename: @csv_file.original_filename
      }.to_json
    )
  end
end