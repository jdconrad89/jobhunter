class AddDescriptionToJobPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :job_posts, :description, :text
  end
end
