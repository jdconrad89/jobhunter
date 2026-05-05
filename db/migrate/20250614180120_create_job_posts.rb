class CreateJobPosts < ActiveRecord::Migration[8.0]
  def change
    create_table :job_posts do |t|
      t.references :company, null: false, foreign_key: true
      t.string :title
      t.string :url

      t.timestamps
    end
    add_index :job_posts, :url, unique: true
  end
end
