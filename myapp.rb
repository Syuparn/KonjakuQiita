require 'sinatra'
require 'sinatra/reloader'
require 'sass'
require 'haml'
require 'sinatra/activerecord'
require './models/tag.rb'

Tag.delete_all
# mock data
results = [['Ruby', 10], ['Python', 5], ['PHP', 4], ['js', 2]]
results.each do |result|
  Tag.create(name: result[0], num_likes: result[1])
end

get '/' do
  @title = "show tags"
  @tags = Tag.order("num_likes desc").all
  erb :index
end
