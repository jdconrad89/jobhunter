class HashApiTokensOnUsers < ActiveRecord::Migration[8.0]
  def change
    remove_index :users, :api_token, if_exists: true
    remove_column :users, :api_token, :string

    add_column :users, :api_token_digest, :string
    add_index :users, :api_token_digest, unique: true
  end
end
