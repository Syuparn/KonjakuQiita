require 'sinatra'
require 'sinatra/reloader'
require 'sass'
require 'haml'

get '/' do
  erb :index
end
