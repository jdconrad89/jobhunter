class AddLocationToJobPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :job_posts, :location, :string
  end
end
