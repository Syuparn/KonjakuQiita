class FixTags2 < ActiveRecord::Migration[5.2]
  def change
    drop_table :tags
    create_table :tags do |t|
      t.string :name
      t.integer :num_articles
      t.datetime :created_at
    end
  end
end
