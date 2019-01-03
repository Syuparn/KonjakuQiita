require 'open-uri'
require 'json'
# require is relative to root path
require './models/tag'

namespace :qiita_api do
  NUM_TAGS = 100

  def fetch_tags()
    f = open(
      "https://qiita.com/api/v2/tags?page=1&per_page=#{NUM_TAGS}&sort=count",
      'Content-Type' => 'application/json',
    )
    JSON.parse(f.read)
  end

  def record_tags(tags)
    if tags.size != NUM_TAGS
      # somehow failed to fetch all tags, so skip updating
      return
    end

    Tag.delete_all
    tags.each do |tag|
      Tag.create(name: tag['id'], num_articles: tag['items_count'].to_i)
    end
  end


  desc "fetch tag data (the most popular #{NUM_TAGS}) by Qiita API"
  task :update_tags do
    # already sorted by items_count (= num_articles)
    new_tags = fetch_tags()
    record_tags(new_tags)
  end
end
