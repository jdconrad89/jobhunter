class AddExperienceYearsToJobPosts < ActiveRecord::Migration[8.0]
  def up
    add_column :job_posts, :experience_years_min, :integer
    add_column :job_posts, :experience_years_max, :integer
    add_index :job_posts, :experience_years_min
    add_index :job_posts, :experience_years_max

    JobPost.reset_column_information
    JobPost.find_each do |job_post|
      min_max = job_post.parse_experience_years
      next unless min_max

      job_post.update_columns(
        experience_years_min: min_max[0],
        experience_years_max: min_max[1]
      )
    end
  end

  def down
    remove_index :job_posts, :experience_years_max, if_exists: true
    remove_index :job_posts, :experience_years_min, if_exists: true
    remove_column :job_posts, :experience_years_max
    remove_column :job_posts, :experience_years_min
  end
end
