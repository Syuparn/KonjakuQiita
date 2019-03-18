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

  def year
    created_at.year
  end

  def badge_color
    # color gradation depending on diff_year
    # diff_year==0(now): "success" in Bootstrap
    # ...(gradation)... diff_year==10(10 years ago): yellow
    success_color = {r: 40, g: 167, b: 69}
    old_color = {r: 225, g: 219, b: 103}
    if diff_year >= 10
      # use color old directly
      colorcode(old_color)
    else
      gradated_color = success_color.map {|k,v|
        [k, ((v*(10-diff_year) + old_color[k]*diff_year)/10).to_i]}.to_h
      colorcode(gradated_color)
    end
  end

  private
  def diff_year
    today = Time.now
    ((today - created_at) / (365 * 24 * 60 * 60)).to_i
  end

  def colorcode(colorhash)
    # i.e. {r: 16, g: 32, b: 64} -> "#102040"
    %Q{##{colorhash[:r].to_s(16)}#{colorhash[:g].to_s(16)}#{colorhash[:b].to_s(16)}}
  end
end
