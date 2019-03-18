require 'sinatra/activerecord'

# connect to db
configure :development, :test do
  db_config = YAML.load_file('config/database.yml')
  ActiveRecord::Base.establish_connection(db_config['development'])
end

configure :production do
  ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
end


class Tag < ActiveRecord::Base
  def url
    # replace "#" to %23 not to be treated as sanitized space
    "/ranking/#{name.gsub(/#/, '%23')}"
  end
end
