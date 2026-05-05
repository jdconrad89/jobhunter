class ChangeNumberOfJobsToInteger < ActiveRecord::Migration[8.0]
  def up
    change_column_default :job_searches, :number_of_jobs, from: "0", to: nil
    change_column :job_searches, :number_of_jobs, :integer, using: "number_of_jobs::integer"
    change_column_default :job_searches, :number_of_jobs, from: nil, to: 0
  end

  def down
    change_column_default :job_searches, :number_of_jobs, from: 0, to: nil
    change_column :job_searches, :number_of_jobs, :string, using: "number_of_jobs::text"
    change_column_default :job_searches, :number_of_jobs, from: nil, to: "0"
  end
end
