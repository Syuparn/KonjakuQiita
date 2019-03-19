require 'sinatra'
require 'sinatra/reloader'
require 'sass'
require 'haml'
require 'sinatra/activerecord'
require './models/tag'
require './models/article'


class SortController
  def initialize(sort_key)
    @sort_key = sort_key
  end

  def order
    {
      article: 'num_articles desc',
      name: 'name asc',
      year: 'created_at asc'
    }[@sort_key]
  end

  def button_status(key)
    @sort_key == key ? 'active' : ''
  end

  attr_reader :sort_key
end


class SearchController
  def initialize(search_key=nil)
    @search_key = search_key
  end

  def description
    @search_key ? %Q{contains "#{@search_key}"} : "all"
  end

  def sorted_page_uri(sort_key)
    if @search_key
      # add query
      "#{sorted_page_url(sort_key)}?inputTagName=#{@search_key}"
    else
      sorted_page_url(sort_key)
    end
  end

  private
  def sorted_page_url(sort_key)
    sort_url = "sortby_#{sort_key}"
    @search_key ? "/search_tags/#{sort_url}" : "/#{sort_url}"
  end
end


get '/' do
  redirect '/sortby_article'
end

[:article, :name, :year].each do |sort_key|
  get "/sortby_#{sort_key}" do
    @sort_controller = SortController.new(sort_key)
    @tags = Tag.order(@sort_controller.order).all
    # FIXME: hide tags untied with articles (tentatively hide tags created_at>=2019)
    @tags = @tags.select {|t| t.year < 2019}
    @search_controller = SearchController.new()
    erb :index
  end

  get "/search_tags/sortby_#{sort_key}" do
    @sort_controller = SortController.new(sort_key)
    search_key = params[:inputTagName]
    @tags = Tag.where('name like ?', "%#{search_key}%").order(@sort_controller.order).all
    # FIXME: hide tags untied with articles (tentatively hide tags created_at>=2019)
    @tags = @tags.select {|t| t.year < 2019}
    @search_controller = SearchController.new(search_key)
    erb :index
  end
end

get '/ranking/*' do |tag_name|
  @tag = tag_name
  @oldest_article = Article.where(tag1: @tag).order("num_likes desc").all[0]
  if @oldest_article.nil?
    erb :not_found
  else
    erb :ranking
  end
end

get '/about' do
  erb :about
end
