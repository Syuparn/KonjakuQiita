require 'sinatra'
require 'sinatra/reloader'
require 'sass'
require 'haml'
require 'sinatra/activerecord'
require './models/tag'

get '/' do
  @title = "show tags"
  @tags = Tag.order("num_articles desc").all
  erb :index
end
