# Save this file as role_debugger.rb in your Rails app root directory

# This script helps debug user roles in your application
# Run it with: rails runner role_debugger.rb

class RoleDebugger
  def self.run
    puts "===== USER ROLE DEBUGGER ====="
    puts "This tool will help diagnose issues with user roles in your application."
    
    # List all users and their roles
    list_all_users
    
    # Prompt for actions
    prompt_for_action
  end

  def self.list_all_users
    puts "\n[LISTING ALL USERS]"
    begin
      users = WebsiteUser.all
      
      if users.empty?
        puts "No users found in the database."
        return
      end
      
      puts "Found #{users.count} users:"
      users.each_with_index do |user, index|
        role = user.respond_to?(:role) ? user.role : "unknown"
        puts "#{index + 1}. ID: #{user.id}, Email: #{user.email}, Role: #{role}"
      end
    rescue => e
      puts "ERROR: #{e.message}"
    end
  end
  
  def self.show_user_details(user_id)
    begin
      user = WebsiteUser.find(user_id)
      puts "\n[USER DETAILS]"
      puts "ID: #{user.id}"
      puts "Email: #{user.email}"
      
      # Display all attributes
      puts "\nAll attributes:"
      user.attributes.each do |key, value|
        puts "  #{key}: #{value}"
      end
      
      # Specific role information
      if user.respond_to?(:role)
        puts "\nRole: #{user.role}"
      else
        puts "\nWARNING: User model does not have a role attribute/method."
      end
    rescue ActiveRecord::RecordNotFound
      puts "User with ID #{user_id} not found."
    rescue => e
      puts "ERROR: #{e.message}"
    end
  end
  
  def self.update_user_role(user_id, new_role)
    begin
      user = WebsiteUser.find(user_id)
      
      if !user.respond_to?(:role=)
        puts "ERROR: Cannot update role. User model doesn't have a role attribute that can be set."
        return
      end
      
      old_role = user.role
      user.role = new_role
      
      if user.save
        puts "SUCCESS: Updated user #{user.email}'s role from '#{old_role}' to '#{new_role}'."
      else
        puts "ERROR: Failed to update role. Validation errors: #{user.errors.full_messages.join(', ')}"
      end
    rescue ActiveRecord::RecordNotFound
      puts "User with ID #{user_id} not found."
    rescue => e
      puts "ERROR: #{e.message}"
    end
  end
  
  def self.check_database_schema
    puts "\n[DATABASE SCHEMA INFORMATION]"
    begin
      if ActiveRecord::Base.connection.table_exists?(:website_users)
        columns = ActiveRecord::Base.connection.columns(:website_users)
        puts "WebsiteUser table columns:"
        columns.each do |column|
          puts "  #{column.name}: #{column.type}"
        end
        
        # Check if role column exists
        if columns.any? { |c| c.name == "role" }
          puts "\n✅ Role column exists in website_users table."
          # Check role values in the database
          role_values = WebsiteUser.pluck(:role).uniq.compact
          puts "Unique role values in database: #{role_values.empty? ? 'none' : role_values.join(', ')}"
        else
          puts "\n❌ Role column does NOT exist in website_users table."
        end
      else
        puts "WebsiteUser table does not exist."
      end
    rescue => e
      puts "ERROR checking schema: #{e.message}"
    end
  end
  
  def self.prompt_for_action
    loop do
      puts "\n[ACTIONS]"
      puts "1. List all users"
      puts "2. View user details (by ID)"
      puts "3. Update user role (by ID)"
      puts "4. Check database schema"
      puts "5. Exit"
      
      print "\nSelect an action (1-5): "
      choice = STDIN.gets.chomp
      
      case choice
      when "1"
        list_all_users
      when "2"
        print "Enter user ID: "
        user_id = STDIN.gets.chomp.to_i
        show_user_details(user_id)
      when "3"
        print "Enter user ID: "
        user_id = STDIN.gets.chomp.to_i
        print "Enter new role (admin/viewer): "
        new_role = STDIN.gets.chomp
        update_user_role(user_id, new_role)
      when "4"
        check_database_schema
      when "5"
        puts "Exiting."
        break
      else
        puts "Invalid choice. Please select 1-5."
      end
    end
  end
end

# Run the debugger
RoleDebugger.run