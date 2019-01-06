require 'open-uri'
require 'json'
require 'uri'
require 'date'
# require is relative to root path
require './models/tag'
require './models/article'

namespace :qiita_api do
  NUM_TAGS = 100
  PER_PAGE = 100
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
      p "failed to fetch tags by qiita API"
      return
    end

    Tag.delete_all
    tags.each do |tag|
      Tag.create(name: tag['id'], num_articles: tag['items_count'].to_i)
    end
  end

  def fetch_articles(tag_name, is_new:)
    max_page = Tag.find_by(name: tag_name).num_articles.div(PER_PAGE)
    # TODO: fetch also max_page + 1
    if is_new
      # latest articles
      page = 1
    else
      # oldest articles (NOTE: page = 100 is oldest page API can handle)
      page = [max_page, 100].min
    end

    uri = "https://qiita.com/api/v2/items?page=#{page}&per_page=#{PER_PAGE}&query=tag:#{tag_name}"
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

  def update_articles(tag, is_new:)
    articles = fetch_articles(tag, is_new: is_new)
    # pick up NUM_SELECTED_ARTICLES articles which have the most likes
    selected_articles = articles.sort_by{|a| a['likes_count']}.reverse![0..NUM_SELECTED_ARTICLES-1]
    record_articles(tag, selected_articles, is_new: is_new)
  end

  def todays_updating_range(n_max)
    # separate range of length n_max (0..n_max-1) into 7 days
    # Sun: 0..n_max/7-1, Mon: n_max/7..2*n_max/7-1, ... Sat: 6*n_max/7..n_max-1
    # this is used for Heroku Scheduler, which only supports 1-day each task
    day = DateTime.now.wday
    if day == 6 # Sat
      (day * n_max.div(7))..(n_max - 1)
    else
      (day * n_max.div(7))..((day + 1) * n_max.div(7) - 1)
    end
  end

  desc "update tag table (the most popular #{NUM_TAGS}) by Qiita API"
  task :update_tags do
    # already sorted by items_count (= num_articles)
    new_tags = fetch_tags()
    record_tags(new_tags)
  end

  desc "update article table by Qiita API"
  task :update_articles do
    tag_names = Tag.order("num_articles desc").all.map { |t| t.name }
    tag_names[todays_updating_range(NUM_TAGS)].each do |tag_name|
      update_articles(tag_name, is_new: true)
      sleep(5)
      update_articles(tag_name, is_new: false)
      sleep(5)
    end
  end

  desc "delete all in article table"
  #TODO: move to other rake
  task :reset_articles! do
    Article.delete_all()
  end
end
