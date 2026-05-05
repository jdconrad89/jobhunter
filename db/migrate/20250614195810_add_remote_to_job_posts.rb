class AddRemoteToJobPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :job_posts, :remote, :boolean
  end
end
