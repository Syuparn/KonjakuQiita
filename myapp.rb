require 'sinatra'
require 'sinatra/reloader'
require 'sass'
require 'haml'
require 'sinatra/activerecord'

configure :development, :test do
  db_config = YAML.load_file('config/database.yml')
  ActiveRecord::Base.establish_connection(db_config['development'])
end

configure :production do
  ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
end


class Tag < ActiveRecord::Base
end

# mock data
Tag.delete_all
results = [['Ruby', 10], ['Python', 5], ['PHP', 4], ['js', 2]]
results.each do |result|
  Tag.create(name: result[0], num_likes: result[1])
end

get '/' do
  @title = "show tags"
  @tags = Tag.order("num_likes desc").all
  erb :index
end
