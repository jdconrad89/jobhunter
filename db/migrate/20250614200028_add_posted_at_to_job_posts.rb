class AddPostedAtToJobPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :job_posts, :posted_at, :datetime, null: true
  end
end
