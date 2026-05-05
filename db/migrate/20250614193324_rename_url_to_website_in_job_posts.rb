class RenameUrlToWebsiteInJobPosts < ActiveRecord::Migration[8.0]
  def change
    rename_column :job_posts, :url, :website
  end
end
