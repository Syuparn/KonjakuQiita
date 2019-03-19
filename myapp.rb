require 'sinatra'
require 'sinatra/reloader'
require 'sass'
require 'haml'
require 'sinatra/activerecord'
require './models/tag'
require './models/article'

tag_sort_order = {
  article: 'num_articles desc',
  name: 'name asc',
  year: 'created_at asc'
}

sorted_page_route = {
  article: '', # index page '/' == sorted by articles
  name: 'sortby_name',
  year: 'sortby_year'
}

sorted_page_route.each do |sort_key, page_route|
  get "/#{page_route}" do
    @tags = Tag.order(tag_sort_order[sort_key]).all
    # FIXME: hide tags untied with articles (tentatively hide tags created_at>=2019)
    @tags = @tags.select {|t| t.year < 2019}
    @sort_key = sort_key
    @searched_by = 'all'
    @main_route = '/'
    erb :index
  end

  get "/search_tags/#{page_route}" do
    @search_key = params[:inputTagName]
    @tags = Tag.where('name like ?', "%#{@search_key}%").order(tag_sort_order[sort_key]).all
    # FIXME: hide tags untied with articles (tentatively hide tags created_at>=2019)
    @tags = @tags.select {|t| t.year < 2019}
    @sort_key = sort_key
    @searched_by = %Q{contains "#{@search_key}"}
    @main_route = '/search_tags/'
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
