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

  def diff_year
    today = Time.now
    ((today - created_at) / (365 * 24 * 60 * 60)).to_i
  end

  def notation_color
    case diff_year
    when 1..2
      '#fff3cd'
    when 3..4
      '#ffe79a'
    when 5..Float::INFINITY
      '#ffdb67'
    else
      nil
    end
  end
end
