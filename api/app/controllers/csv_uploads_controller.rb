class CsvUploadsController < ApplicationController
  before_action :require_admin

  def new
    # Show the CSV upload form
  end

  def create
    unless params[:csv_file].present?
      render json: { error: 'No CSV file provided' }, status: :bad_request
      return
    end

    csv_file = params[:csv_file]
    provider = params[:provider] || 'generic'

    Rails.logger.info "CSV upload request received: #{params.inspect}"
    
    # Validate file type
    unless csv_file.content_type.in?(['text/csv', 'application/vnd.ms-excel', 'text/plain'])
      render json: { error: 'Invalid file type. Please upload a CSV file.' }, status: :bad_request
      return
    end

    begin
      # Create import record for tracking
      csv_import = CsvImport.create!(
        filename: csv_file.original_filename,
        provider: provider,
        uploaded_by: current_user.id,
        status: 'processing'
      )

      # Process the CSV file
      processor = CsvProcessorService.new(csv_file, provider, current_user)
      result = processor.process

      # Update import record with results
      csv_import.update!(
        status: result[:success] ? 'completed' : 'failed',
        total_rows: result[:total_rows],
        processed_rows: result[:processed_rows],
        failed_rows: result[:failed_rows],
        error_details: result[:errors],
        processing_summary: result[:summary]
      )

      if result[:success]
        render json: {
          message: 'CSV processed successfully',
          summary: result[:summary],
          import_id: csv_import.id
        }, status: :ok
      else
        render json: {
          error: 'CSV processing completed with errors',
          errors: result[:errors],
          summary: result[:summary],
          import_id: csv_import.id
        }, status: :unprocessable_entity
      end

    rescue => e
      # Update import record if it was created
      csv_import&.update!(
        status: 'failed',
        error_details: [e.message]
      )
      
      Rails.logger.error "CSV Upload Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      render json: { 
        error: 'An error occurred while processing the CSV file',
        details: e.message 
      }, status: :internal_server_error
    end
  end

  def show
    # Show details of a specific CSV import
    csv_import = CsvImport.find(params[:id])
    render json: csv_import
  end

  def index
    # List all CSV imports with pagination
    csv_imports = CsvImport.order(created_at: :desc)
                          .page(params[:page])
                          .per(params[:per_page] || 25)
    
    render json: {
      imports: csv_imports,
      pagination: {
        current_page: csv_imports.current_page,
        total_pages: csv_imports.total_pages,
        total_count: csv_imports.total_count
      }
    }
  end

  private

  def require_admin
    unless current_user&.admin?
      render json: { error: 'Admin access required' }, status: :forbidden
    end
  end
end