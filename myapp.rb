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

get '/debug' do
  @tags = Tag.order("num_articles desc").all
  @articles = Article.all[1..10]
  @articles.each { |article|
    puts "#{article.name}: #{article.num_likes} #{article.tag1} #{article.tag2} #{article.tag3} #{article.tag4} #{article.tag5} #{article.created_at}"
  }
end

get '/ranking/*' do |tag_name|
  @tag = tag_name
  @oldest_article = Article.where(tag1: @tag).order("num_likes desc").all[0]
  erb :ranking
end
