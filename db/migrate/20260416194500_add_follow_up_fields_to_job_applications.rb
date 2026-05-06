class AddFollowUpFieldsToJobApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :job_applications, :contact_info, :text
    add_column :job_applications, :followed_up, :boolean, null: false, default: false
  end
end
