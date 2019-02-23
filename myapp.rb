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

get '/sample' do
  erb :sample
end

get '/ranking/*' do |tag_name|
  @tag = tag_name
  @new_articles = Article.where(tag1: @tag).where(new?: true).order("num_likes desc").all[0..9]
  @old_articles = Article.where(tag1: @tag).where(new?: false).order("num_likes desc").all[0..9]
  erb :ranking
end
