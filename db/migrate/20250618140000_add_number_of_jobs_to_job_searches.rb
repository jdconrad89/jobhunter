class AddNumberOfJobsToJobSearches < ActiveRecord::Migration[8.0]
  def up
    add_column :job_searches, :number_of_jobs, :string, default: "0"

    # Backfill existing job searches
    JobSearch.reset_column_information
    JobSearch.find_each do |job_search|
      job_search.update_number_of_jobs!
    end
  end

  def down
    remove_column :job_searches, :number_of_jobs
  end
end
