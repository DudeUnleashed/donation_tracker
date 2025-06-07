# app/models/csv_import.rb
class CsvImport < ApplicationRecord
  belongs_to :uploader, class_name: 'WebsiteUser', foreign_key: 'uploaded_by'
  
  validates :filename, presence: true
  validates :provider, presence: true, inclusion: { in: %w[paypal stripe square generic] }
  validates :status, inclusion: { in: %w[pending processing completed failed] }
  validates :uploaded_by, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_provider, ->(provider) { where(provider: provider) }
  scope :successful, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :this_month, -> { where(created_at: Time.current.beginning_of_month..Time.current.end_of_month) }
  scope :today, -> { where(created_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  
  def success_rate
    return 0 if total_rows == 0
    ((processed_rows.to_f / total_rows) * 100).round(2)
  end
  
  def failure_rate
    return 0 if total_rows == 0
    ((failed_rows.to_f / total_rows) * 100).round(2)
  end
  
  def has_errors?
    error_details.present? && error_details.any?
  end
  
  def processing_complete?
    status.in?(%w[completed failed])
  end
  
  def processing_in_progress?
    status.in?(%w[pending processing])
  end
  
  def summary_text
    if processing_summary.present?
      summary = processing_summary.with_indifferent_access
      text = "Processed #{processed_rows}/#{total_rows} rows"
      
      if summary['new_users'] && summary['new_donations']
        text += " • #{summary['new_users']} new users"
        text += " • #{summary['new_donations']} new donations"
      end
      
      if summary['duplicate_donations'] && summary['duplicate_donations'] > 0
        text += " • #{summary['duplicate_donations']} duplicates skipped"
      end
      
      text
    else
      case status
      when 'pending' then 'Queued for processing'
      when 'processing' then 'Currently processing...'
      when 'completed' then 'Successfully completed'
      when 'failed' then 'Processing failed'
      else status.humanize
      end
    end
  end
  
  def provider_name
    case provider
    when 'paypal' then 'PayPal'
    when 'stripe' then 'Stripe'
    when 'square' then 'Square'
    when 'generic' then 'Generic/Manual'
    else provider.humanize
    end
  end
  
  def status_badge_class
    case status
    when 'completed' then 'success'
    when 'failed' then 'danger'
    when 'processing' then 'warning'
    when 'pending' then 'info'
    else 'secondary'
    end
  end
  
  def duration_text
    return 'Not started' unless processing_complete?
    
    if updated_at && created_at
      duration = updated_at - created_at
      if duration < 60
        "#{duration.round}s"
      elsif duration < 3600
        "#{(duration / 60).round}m"
      else
        "#{(duration / 3600).round(1)}h"
      end
    else
      'Unknown'
    end
  end
  
  # Class methods for dashboard statistics
  def self.stats_for_period(start_date, end_date)
    imports = where(created_at: start_date..end_date)
    {
      total_imports: imports.count,
      successful_imports: imports.successful.count,
      failed_imports: imports.failed.count,
      total_rows_processed: imports.sum(:processed_rows),
      total_rows_failed: imports.sum(:failed_rows),
      average_success_rate: imports.where.not(total_rows: 0).average('(processed_rows * 100.0 / total_rows)')&.round(2) || 0
    }
  end
  
  def self.recent_activity(limit = 10)
    recent.limit(limit).includes(:uploader)
  end
end