require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/activerecord/rake'

# read all .rake files (,which define tasks) in lib/tasks
Dir.glob('lib/tasks/*.rake').each { |r| load r}

# db migration/connection
configure :development, :test do
  db_config = YAML.load_file('config/database.yml')
  ActiveRecord::Base.establish_connection(db_config['development'])
end

configure :production do
  ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
end
