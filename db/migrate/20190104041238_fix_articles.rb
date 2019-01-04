class FixArticles < ActiveRecord::Migration[5.2]
  def change
    create_table :articles do |t|
      t.string :name
      t.integer :num_likes
      # each article has at most 5 tags
      # https://help.qiita.com/ja/articles/qiita-tagging
      t.string :tag1
      t.string :tag2
      t.string :tag3
      t.string :tag4
      t.string :tag5
      t.string :url
      t.datetime :created_at
      t.datetime :updated_at
      t.string :author_id
      t.string :author_name
      t.boolean :new?
    end
  end
end
