class CreateResumeSuggestions < ActiveRecord::Migration[8.0]
  def change
    create_table :resume_suggestions do |t|
      t.references :resume, null: false, foreign_key: true
      t.references :job_post, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.jsonb :suggestions, null: false, default: {}
      t.string :error_message

      t.timestamps
    end

    add_index :resume_suggestions, [ :resume_id, :job_post_id ], unique: true
  end
end
