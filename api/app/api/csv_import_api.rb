require 'ostruct'

class CsvImportApi < Grape::API
  format :json
  prefix :api

  helpers do
    def current_user
      @current_user ||= begin
        token = headers['Authorization']&.split(' ')&.last
        return nil unless token
        
        decoded_token = JWT.decode(token, Rails.application.credentials.secret_key_base)[0]
        WebsiteUser.find_by(id: decoded_token['admin_id'])
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound
        nil
      end
    end

    def authenticate!
      error!('Unauthorized', 401) unless current_user
    end

    def require_admin!
      authenticate!
      error!('Admin access required', 403) unless current_user.admin?
    end
  end

  # Upload and process CSV file
  desc 'Upload CSV file for processing'
  params do
    requires :csv_file, type: File, desc: 'CSV file to upload'
    optional :provider, type: String, desc: 'Payment provider type', 
             values: %w[paypal stripe square generic], default: 'generic'
  end
  post '/csv_upload' do
    require_admin!
    
    csv_file = params[:csv_file]
    provider = params[:provider]
    
    # Validate file type
    unless csv_file[:type].in?(['text/csv', 'application/vnd.ms-excel', 'text/plain'])
      error!('Invalid file type. Please upload a CSV file.', 400)
    end
    
    begin
      # Create import record
      csv_import = CsvImport.create!(
        filename: csv_file[:filename],
        provider: provider,
        uploaded_by: current_user.id,
        status: 'processing'
      )

      # Create a temporary file for processing
      temp_file = Tempfile.new(['csv_upload', '.csv'])
      temp_file.binmode
      temp_file.write(csv_file[:tempfile].read)
      temp_file.rewind

      # Create a simple file-like object that responds to the methods our service expects
      file_wrapper = OpenStruct.new(
        read: temp_file.read,
        original_filename: csv_file[:filename]
      )
      temp_file.rewind

      # Process the CSV
      processor = CsvProcessorService.new(file_wrapper, provider, current_user)
      result = processor.process

      # Update import record
      csv_import.update!(
        status: result[:success] ? 'completed' : 'failed',
        total_rows: result[:total_rows],
        processed_rows: result[:processed_rows],
        failed_rows: result[:failed_rows],
        error_details: result[:errors],
        processing_summary: result[:summary]
      )

      # Clean up temp file
      temp_file.close
      temp_file.unlink

      if result[:success]
        {
          success: true,
          message: 'CSV processed successfully',
          import_id: csv_import.id,
          summary: result[:summary]
        }
      else
        error!({
          success: false,
          message: 'CSV processing completed with errors',
          import_id: csv_import.id,
          errors: result[:errors],
          summary: result[:summary]
        }, 422)
      end

    rescue => e
      csv_import&.update!(
        status: 'failed',
        error_details: [e.message]
      )
      
      temp_file&.close
      temp_file&.unlink
      
      error!("Processing error: #{e.message}", 500)
    end
  end

  # Get CSV import history
  desc 'Get CSV import history'
  params do
    optional :page, type: Integer, default: 1, desc: 'Page number'
    optional :per_page, type: Integer, default: 25, desc: 'Items per page'
    optional :status, type: String, desc: 'Filter by status'
    optional :provider, type: String, desc: 'Filter by provider'
  end
  get '/csv_imports' do
    require_admin!
    
    imports = CsvImport.includes(:uploader).order(created_at: :desc)
    
    imports = imports.by_status(params[:status]) if params[:status].present?
    imports = imports.by_provider(params[:provider]) if params[:provider].present?
    
    # Simple pagination
    offset = (params[:page] - 1) * params[:per_page]
    total_count = imports.count
    paginated_imports = imports.limit(params[:per_page]).offset(offset)
    
    {
      imports: paginated_imports.map do |import|
        {
          id: import.id,
          filename: import.filename,
          provider: import.provider,
          status: import.status,
          uploaded_by: import.uploader.email,
          uploaded_at: import.created_at,
          total_rows: import.total_rows,
          processed_rows: import.processed_rows,
          failed_rows: import.failed_rows,
          success_rate: import.success_rate,
          summary: import.summary_text,
          has_errors: import.has_errors?
        }
      end,
      pagination: {
        current_page: params[:page],
        per_page: params[:per_page],
        total_count: total_count,
        total_pages: (total_count.to_f / params[:per_page]).ceil
      }
    }
  end

  # Get details of a specific import
  desc 'Get CSV import details'
  params do
    requires :id, type: Integer, desc: 'Import ID'
  end
  get '/csv_imports/:id' do
    require_admin!
    
    import = CsvImport.find(params[:id])
    
    {
      id: import.id,
      filename: import.filename,
      provider: import.provider,
      status: import.status,
      uploaded_by: import.uploader.email,
      uploaded_at: import.created_at,
      total_rows: import.total_rows,
      processed_rows: import.processed_rows,
      failed_rows: import.failed_rows,
      success_rate: import.success_rate,
      error_details: import.error_details,
      processing_summary: import.processing_summary
    }
  end

  # Get available providers and their expected CSV formats
  desc 'Get CSV format templates for different providers'
  get '/csv_templates' do
    authenticate!
    
    {
      providers: {
        paypal: {
          name: 'PayPal',
          required_columns: ['payer_email', 'gross', 'date'],
          optional_columns: ['name', 'transaction_id', 'currency'],
          sample_data: {
            payer_email: 'donor@example.com',
            name: 'John Donor',
            gross: '25.00',
            date: '2024-01-15 10:30:00',
            transaction_id: 'TXN123456',
            currency: 'USD'
          }
        },
        stripe: {
          name: 'Stripe',
          required_columns: ['customer_email', 'amount', 'created'],
          optional_columns: ['customer_name', 'id', 'currency'],
          sample_data: {
            customer_email: 'donor@example.com',
            customer_name: 'John Donor',
            amount: '2500',
            created: '2024-01-15T10:30:00Z',
            id: 'ch_1234567890',
            currency: 'usd'
          }
        },
        square: {
          name: 'Square',
          required_columns: ['buyer_email_address', 'total_money', 'created_at'],
          optional_columns: ['buyer_name', 'id', 'currency'],
          sample_data: {
            buyer_email_address: 'donor@example.com',
            buyer_name: 'John Donor',
            total_money: '25.00',
            created_at: '2024-01-15 10:30:00',
            id: 'SQ123456',
            currency: 'USD'
          }
        },
        generic: {
          name: 'Generic',
          required_columns: ['email', 'amount', 'date'],
          optional_columns: ['username', 'name', 'transaction_id', 'platform', 'currency'],
          sample_data: {
            email: 'donor@example.com',
            username: 'johndonor',
            amount: '25.00',
            date: '2024-01-15',
            transaction_id: 'TXN123456',
            platform: 'Manual',
            currency: 'USD'
          }
        }
      }
    }
  end
end