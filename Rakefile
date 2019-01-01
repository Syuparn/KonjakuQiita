require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/activerecord/rake'

configure :development, :test do
  db_config = YAML.load_file('config/database.yml')
  ActiveRecord::Base.establish_connection(db_config['development'])
end

configure :production do
  ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
end
