require 'sinatra'
require 'sinatra/reloader'
require 'sass'
require 'haml'
require 'sinatra/activerecord'
require './models/tag'
require './models/article'

def diff_year(date)
  today = Time.now
  ((today - date) / (365 * 24 * 60 * 60)).to_i
end

def diff_year_notation_color(diff_year)
  if diff_year >= 5
    '#ffdb67'
  elsif diff_year >= 3
    '#ffe79a'
  elsif diff_year >= 1
    '#fff3cd'
  else
    nil
  end
end

get '/' do
  @tags = Tag.order("num_articles desc").all
  erb :index
end

get '/ranking/*' do |tag_name|
  @tag = tag_name
  @oldest_article = Article.where(tag1: @tag).order("num_likes desc").all[0]
  @diff_year = diff_year(@oldest_article.created_at)
  @notation_color = diff_year_notation_color(@diff_year)
  erb :ranking
end
