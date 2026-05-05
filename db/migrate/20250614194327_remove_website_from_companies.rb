class RemoveWebsiteFromCompanies < ActiveRecord::Migration[8.0]
  def change
    remove_column :companies, :website, :string
  end
end
