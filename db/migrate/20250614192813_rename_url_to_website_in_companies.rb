class RenameUrlToWebsiteInCompanies < ActiveRecord::Migration[8.0]
  def change
    rename_column :companies, :url, :website
  end
end
