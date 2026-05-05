class AddRuntimeToJobSearches < ActiveRecord::Migration[8.0]
  def change
    add_column :job_searches, :runtime, :datetime
    add_column :job_searches, :timezone, :string
  end
end
