class CreateDocuments < ActiveRecord::Migration[5.0]
  def up
    create_table :documents, id: false do |t|
      t.string :id, :primary_key => true, null: false
      t.string :name, null: false
      t.string :xml, null: false
      t.string :csv

      t.timestamps
    end
  end

  def down
    drop_table :documents
  end
end
