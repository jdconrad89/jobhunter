class CreateResumes < ActiveRecord::Migration[8.0]
  def change
    create_table :resumes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.text :extracted_text
      t.integer :extraction_status, null: false, default: 0
      t.string :extraction_error
      t.boolean :is_default, null: false, default: false

      t.timestamps
    end
  end
end
