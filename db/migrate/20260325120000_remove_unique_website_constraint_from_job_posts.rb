class RemoveUniqueWebsiteConstraintFromJobPosts < ActiveRecord::Migration[8.0]
  def change
    reversible do |dir|
      dir.up do
        remove_index :job_posts, name: "index_job_posts_on_job_search_id_and_website"
        add_index :job_posts, [ :job_search_id, :website ], name: "index_job_posts_on_job_search_id_and_website"
      end

      dir.down do
        remove_index :job_posts, name: "index_job_posts_on_job_search_id_and_website"
        add_index :job_posts, [ :job_search_id, :website ], name: "index_job_posts_on_job_search_id_and_website", unique: true
      end
    end
  end
end
