require 'open-uri'
require 'json'
require 'uri'
# require is relative to root path
require './models/tag'
require './models/article'

namespace :qiita_api do
  NUM_TAGS = 100
  NUM_SELECTED_ARTICLES = 10

  def fetch_tags()
    f = open(
      "https://qiita.com/api/v2/tags?page=1&per_page=#{NUM_TAGS}&sort=count",
      'Content-Type' => 'application/json',
    )
    JSON.parse(f.read)
  end

  def record_tags(tags)
    if tags.size != NUM_TAGS
      # if failed to fetch all tags, skip updating
      return
    end

    Tag.delete_all
    tags.each do |tag|
      Tag.create(name: tag['id'], num_articles: tag['items_count'].to_i)
    end
  end

  def fetch_articles(tag)
    # TODO: get tag arg as hash {name:, num_articles:} (now tag name string)
    i = 1 #newest
    uri = "https://qiita.com/api/v2/items?page=#{i}&per_page=100&query=tag:#{tag}"
    f = open(
      URI.encode(uri),
      'Content-Type' => 'application/json'
    )
    JSON.parse(f.read)
  end

  def record_articles(tag_name, articles, is_new:)
    if articles.length != NUM_SELECTED_ARTICLES
      # if failed to fetch all articles, skip updating
      p "failed to fetch articles of tag: #{tag_name} by qiita API"
      return
    end
    # delete current records
    Article.where(tag1: tag_name).where(new?: is_new).delete_all()

    # make updated records
    articles.each do |article|
      # article['tags'] is array like [{'name': 'tag1', 'versions', []}, ...]
      # tags in article['tags'] except tag_name(given by arg)
      other_tags = article['tags'].map { |tag|  tag['name']}
      other_tags.delete(tag_name)

      # each article has at most 5 tags
      # https://help.qiita.com/ja/articles/qiita-tagging
      Article.create(
        name: article['title'],
        num_likes: article['likes_count'],
        tag1: tag_name,
        tag2: other_tags[0] || nil,
        tag3: other_tags[1] || nil,
        tag4: other_tags[2] || nil,
        tag5: other_tags[3] || nil,
        url: article['url'],
        created_at: article['created_at'],
        updated_at: article['updated_at'],
        author_id: article['id'],
        author_name: article['name'],
        new?: is_new
      )
    end
  end

  desc "update tag table (the most popular #{NUM_TAGS}) by Qiita API"
  task :update_tags do
    # already sorted by items_count (= num_articles)
    new_tags = fetch_tags()
    record_tags(new_tags)
  end

  desc "update article table by Qiita API"
  task :update_new_articles do
    articles = fetch_articles('Ruby')
    #TODO: sort by likes_count
    record_articles('Ruby', articles[0..9], is_new: true)
  end

  desc "delete all in article table"
  #TODO: move to other rake
  task :reset_articles! do
    Article.delete_all()
  end
end
