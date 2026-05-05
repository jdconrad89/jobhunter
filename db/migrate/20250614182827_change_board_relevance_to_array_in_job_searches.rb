class ChangeBoardRelevanceToArrayInJobSearches < ActiveRecord::Migration[7.1]
  def change
    remove_column :job_searches, :board_relevance, :text
    add_column :job_searches, :board_relevance, :string, array: true, default: []
  end
end
