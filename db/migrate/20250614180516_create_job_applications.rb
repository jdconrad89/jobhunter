class CreateJobApplications < ActiveRecord::Migration[8.0]
  def change
    create_table :job_applications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :job_post, null: false, foreign_key: true
      t.datetime :applied_at
      t.string :status

      t.timestamps
    end
  end
end
