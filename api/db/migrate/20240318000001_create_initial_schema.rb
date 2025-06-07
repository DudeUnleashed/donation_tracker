class CreateInitialSchema < ActiveRecord::Migration[7.1]
  def change
    # Create WebsiteUsers table (for admin/viewer login)
    create_table :website_users do |t|
      t.string :username, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :role, default: 'viewer'
      t.datetime :last_login_at
      t.timestamps
      
      t.index :email, unique: true
      t.index :username, unique: true
    end

    # Create Users table (for donation tracking)
    create_table :users do |t|
      t.string :username
      t.string :email
      t.string :platform_id
      t.decimal :lifetime_donations, precision: 10, scale: 2, default: 0
      t.datetime :last_donation_date
      t.string :current_status, default: 'active'
      t.timestamps
      
      t.index :email
      t.index :platform_id
    end

    # Create Donations table
    create_table :donations do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :platform
      t.string :transaction_id
      t.datetime :donation_date
      t.timestamps
      
      t.index :transaction_id
      t.index :donation_date
    end

    # Create AuditLogs table
    create_table :audit_logs do |t|
      t.references :website_user
      t.string :action
      t.string :record_type
      t.bigint :record_id
      t.jsonb :changes
      t.timestamps
      
      t.index [:record_type, :record_id]
    end
  end
end
