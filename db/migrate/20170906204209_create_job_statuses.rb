class CreateJobStatuses < ActiveRecord::Migration[5.0]
  def up
    create_table :job_statuses, id: false do |t|
      t.string :id, :primary_key => true, null: false
      t.string :document_id
      t.integer :status, null: false

      t.timestamps
    end
  end

  def down
    drop_table :job_statuses
  end
end
