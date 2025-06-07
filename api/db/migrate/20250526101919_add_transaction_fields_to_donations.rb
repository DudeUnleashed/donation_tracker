class AddTransactionFieldsToDonations < ActiveRecord::Migration[7.1]
  def change
    # transaction_id already exists, but let's add currency
    add_column :donations, :currency, :string, default: 'USD'
    
    # Remove the existing transaction_id index and add unique constraint
    remove_index :donations, :transaction_id if index_exists?(:donations, :transaction_id)
    add_index :donations, :transaction_id, unique: true, where: "transaction_id IS NOT NULL"
    
    # Add composite index for duplicate detection
    add_index :donations, [:user_id, :amount, :donation_date], name: 'index_donations_on_user_amount_date'
    
    # Add index for platform filtering (if not already exists)
    add_index :donations, :platform unless index_exists?(:donations, :platform)
    
    # Add index for currency
    add_index :donations, :currency
    
    # Add index for donation_date if not already exists  
    add_index :donations, :donation_date unless index_exists?(:donations, :donation_date)
  end
end