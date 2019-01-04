require 'sinatra'
require 'sinatra/reloader'
require 'sass'
require 'haml'
require 'sinatra/activerecord'
require './models/tag'
require './models/article'

get '/' do
  @title = "show tags"
  @tags = Tag.order("num_articles desc").all
  erb :index
end

get '/ranking/*' do |tag_name|
  @tag = tag_name
  @title = "今昔ランキング: #{@tag}"
  @new_articles = Article.where(tag1: @tag).where(new?: true).all
  #@old_articles = Article.where(tag1: @tag).where(new?: false).all
  erb :ranking
end
