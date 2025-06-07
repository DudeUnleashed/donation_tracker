class CreateCsvImports < ActiveRecord::Migration[7.1]
  def change
    create_table :csv_imports do |t|
      t.string :filename, null: false
      t.string :provider, null: false, default: 'generic'
      t.references :website_user, null: false, foreign_key: { column: :uploaded_by }
      t.string :status, null: false, default: 'pending'
      t.integer :total_rows, default: 0
      t.integer :processed_rows, default: 0
      t.integer :failed_rows, default: 0
      t.text :error_details
      t.text :processing_summary

      t.timestamps
    end

    # Rename the reference column to match our expected naming
    rename_column :csv_imports, :website_user_id, :uploaded_by

    add_index :csv_imports, :status
    add_index :csv_imports, :created_at
    add_index :csv_imports, [:provider, :status]
  end
end