class AddPayRangeToJobPosts < ActiveRecord::Migration[8.0]
  def up
    add_column :job_posts, :pay_range_min, :integer
    add_column :job_posts, :pay_range_max, :integer
    add_index :job_posts, :pay_range_min
    add_index :job_posts, :pay_range_max

    # Backfill existing records
    JobPost.reset_column_information
    JobPost.find_each do |job_post|
      min_max = job_post.parse_pay_range_numbers
      if min_max
        job_post.update_columns(pay_range_min: min_max[0], pay_range_max: min_max[1])
      end
    end
  end

  def down
    remove_index :job_posts, :pay_range_max, if_exists: true
    remove_index :job_posts, :pay_range_min, if_exists: true
    remove_column :job_posts, :pay_range_max
    remove_column :job_posts, :pay_range_min
  end
end
