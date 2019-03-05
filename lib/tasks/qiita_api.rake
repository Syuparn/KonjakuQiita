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
  # NOTE: page = 100 is oldest page API can handle)
  MAX_PAGES = 100

  def fetch_tags(page_num)
    f = open(
      "https://qiita.com/api/v2/tags?page=#{page_num}&per_page=#{NUM_TAGS}&sort=count",
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

    tags.each do |tag|
      tag_record = Tag.find_or_initialize_by(name: tag['id'])
      tag_record.update(num_articles: tag['items_count'].to_i)
    end
  end

  def assign_date_to_tag(tag_name, date)
    tag = Tag.find_by(name: tag_name)
    tag.update(created_at: date)
  end

  def fetch_articles(tag_name, page_num, before: nil)
    if tag_name.include?('+')
      uri = URI.encode("https://qiita.com/api/v2/items?page=#{page_num}&per_page=#{PER_PAGE}&query=")
      # replace "+" into "%2b" otherwise tags with "+" will be ignored
      # i.e.: "C++" -> "C  " ("+" is treated as sanitized space)
      uri += "tag:#{tag_name.gsub(/\+/, '%2b')}"
    else
      uri = URI.encode("https://qiita.com/api/v2/items?page=#{page_num}&per_page=#{PER_PAGE}&query=tag:#{tag_name}")
    end
    uri += "+created:<=#{before}" if before
    begin
      f = open(uri, 'Content-Type' => 'application/json')
    rescue OpenURI::HTTPError => e
      p "error raised when fetching #{uri}"
      p e
      return {}
    end
    JSON.parse(f.read)
  end

  def record_article(tag_name, article)
    # delete current records
    Article.where(tag1: tag_name).delete_all()

    # article['tags'] is array like [{'name': 'tag1', 'versions', []}, ...]
    # tags in article['tags'] except tag_name(given by arg)
    other_tags = article['tags'].map { |tag|  tag['name']}
      .tap { |tags| tags.delete(tag_name)}

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
      author_name: article['name']
    )
  end

  def update_articles(tag)
    num_pages = Tag.find_by(name: tag).num_articles.div(PER_PAGE) + 1

    if num_pages <= MAX_PAGES
      articles = fetch_articles(tag, num_pages)
      record_article(tag, articles[-1])
      assign_date_to_tag(tag, articles[-1]['created_at'])
    else
      # fetch 100 pages each
      # 1. get date when oldest article in this 100 pages was created at
      # 2. fetch 100 article pages which is created BEFORE date from 1.
      # 3. return to 1.
      threshold_date = (1..num_pages.div(MAX_PAGES)).to_a.reduce(nil) { |date, _|
        articles = fetch_articles(tag, MAX_PAGES, before: date)
        articles[-1]['created_at'].match('\d\d\d\d\-\d\d-\d\d')[0]
      }
      # refrain from page_num == 0
      page_num = [num_pages % MAX_PAGES, 1].max
      articles = fetch_articles(tag, page_num, before: threshold_date)
      # check next page too (page number gap may occur
      # because pages created at threshold_date are counted twice)
      if articles.length == PER_PAGE && page_num < MAX_PAGES
        older_articles = fetch_articles(tag, page_num + 1, before: threshold_date)
        articles = older_articles if older_articles.length > 0
      end
      record_article(tag, articles[-1])
      assign_date_to_tag(tag, articles[-1]['created_at'])
    end
  end

  def update_hour?()
    # article is updated only during 0:00 ~ 9:00 (fixed to Japan TimeZone!)
    DateTime.now.new_offset('+09:00').hour < 10
  end

  def this_hours_updating_range()
    # NUM_TAGS / 10 articles in every hour during 0:00 ~ 9:00
    # this is used for Heroku Scheduler, which only supports 1-hour each task
    dt = DateTime.now
    if update_hour?
      min = dt.wday * NUM_TAGS + dt.hour * NUM_TAGS.div(10)
      max = dt.wday * NUM_TAGS + (dt.hour + 1) * NUM_TAGS.div(10) - 1
      min..max
    end
  end

  desc "update tag table (the most popular #{7 * NUM_TAGS}) by Qiita API (designate range by hand)"
  # NOTE: CANNOT use "task :update_tags_by_index, ['idx'] => :environment"
  # because :environment can only used in Rails
  task :update_tags_by_index, :idx do |_, args|
    # already sorted by items_count (= num_articles)
    new_tags = fetch_tags(args.idx.to_i)
    record_tags(new_tags)
  end

  desc "update tag table (the most popular #{7 * NUM_TAGS}) by Qiita API"
  task :update_tags do
    # update schedule; Sun: 1, Mon: 2, ..., Sat: 7
    todays_updating_page = DateTime.now.wday + 1
    # already sorted by items_count (= num_articles)
    new_tags = fetch_tags(todays_updating_page)
    record_tags(new_tags)
  end

  desc "update article table by Qiita API"
  task :update_articles do
    tag_names = Tag.order("num_articles desc").all.map { |t| t.name }
    if update_hour?
      tag_names[this_hours_updating_range].each do |tag_name|
        update_articles(tag_name)
        sleep(5)
      end
    end
  end

  desc "update article table by Qiita API (designate range by hand)"
  # NOTE: CANNOT use ":update_articles_by_index, ['start', 'end'] => :environment"
  # because :environment can only used in Rails
  task :update_articles_by_index, :start, :end do |_, args|
    tag_names = Tag.order("num_articles desc").all.map { |t| t.name }
    tag_names[args.start.to_i..args.end.to_i].each do |tag_name|
      update_articles(tag_name)
      sleep(5)
    end
  end

  desc "delete all in article table"
  #TODO: move to other rake
  task :reset_articles! do
    Article.delete_all()
  end
end
