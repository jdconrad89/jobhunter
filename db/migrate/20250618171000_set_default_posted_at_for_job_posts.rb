class SetDefaultPostedAtForJobPosts < ActiveRecord::Migration[8.0]
  def up
    change_column_default :job_posts, :posted_at, -> { "CURRENT_TIMESTAMP" }
    execute <<~SQL
      UPDATE job_posts
      SET posted_at = created_at
      WHERE posted_at IS NULL;
    SQL
  end

  def down
    change_column_default :job_posts, :posted_at, nil
  end
end
