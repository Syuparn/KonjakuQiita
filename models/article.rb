require 'sinatra/activerecord'

# connect to db
configure :development, :test do
  db_config = YAML.load_file('config/database.yml')
  ActiveRecord::Base.establish_connection(db_config['development'])
end

configure :production do
  ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
end


class Article < ActiveRecord::Base
  def formatted_created_at
    created_at.strftime('%Y-%m-%d')
  end

  def formatted_updated_at
    updated_at.strftime('%Y-%m-%d')
  end

  def author
    url.match(%r{https://qiita.com/([^/]+)/})[1]
  end

  def tags
    # tag array (which is not nil)
    [tag1, tag2, tag3, tag4, tag5].compact
  end

  def tag_urls
    # replace "#" to %23 not to be treated as sanitized space
    tags.map {|tag| "/ranking/#{tag.gsub(/#/, '%23')}"}
  end
end
