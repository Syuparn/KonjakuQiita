require 'sinatra'
require 'sinatra/reloader'
require 'sass'
require 'haml'
require 'sinatra/activerecord'
require './models/tag'
require './models/article'

get '/' do
  @tags = Tag.order("num_articles desc").all
  erb :index
end

get '/ranking/*' do |tag_name|
  @tag = tag_name
  @oldest_article = Article.where(tag1: @tag).order("num_likes desc").all[0]
  erb :ranking
end
