class AddJobSearchToJobPosts < ActiveRecord::Migration[8.0]
  def change
    add_reference :job_posts, :job_search, null: true, foreign_key: true

    reversible do |dir|
      dir.up do
        if JobPost.exists? && JobSearch.exists?
          first_job_search_id = JobSearch.first.id
          JobPost.where(job_search_id: nil).update_all(job_search_id: first_job_search_id)
        end
        change_column_null :job_posts, :job_search_id, false
        remove_index :job_posts, :website, unique: true
        add_index :job_posts, [:job_search_id, :website], unique: true
      end
    end
  end
end
