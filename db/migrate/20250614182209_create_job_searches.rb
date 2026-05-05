class CreateJobSearches < ActiveRecord::Migration[7.1]
  def change
    create_table :job_searches do |t|
      t.references :user, null: false, foreign_key: true
      t.string :job_title, null: false
      t.string :location
      t.boolean :remote
      t.string :language_code
      t.text :board_relevance, array: true, default: []

      t.timestamps
    end
  end
end
