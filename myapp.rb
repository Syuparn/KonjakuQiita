require 'sinatra'
require 'sinatra/reloader'
require 'sass'
require 'haml'

get '/' do
  "<h1>hello world!</h1>"
end
