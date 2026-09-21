# frozen_string_literal: true

class RemovePasswordResetColumnsFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_index :users, :reset_password_digest, if_exists: true
    remove_column :users, :reset_password_digest, :string
    remove_column :users, :reset_password_sent_at, :datetime
  end
end
