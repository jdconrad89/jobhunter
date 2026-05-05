class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :name
      t.string :url

      t.timestamps
    end
    add_index :companies, :url, unique: true
  end
end
