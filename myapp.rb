require 'sinatra'
require 'sinatra/reloader'
require 'sass'
require 'haml'
require 'sinatra/activerecord'
require './models/tag'
require './models/article'

def diff_year(date)
  today = Time.now
  ((today - date) / (365 * 24 * 60 * 60)).to_i
end

def diff_year_notation_color(diff_year)
  if diff_year >= 5
    '#ffdb67'
  elsif diff_year >= 3
    '#ffe79a'
  elsif diff_year >= 1
    '#fff3cd'
  else
    nil
  end
end

def colorcode(colorhash)
  %Q{##{colorhash[:r].to_s(16)}#{colorhash[:g].to_s(16)}#{colorhash[:b].to_s(16)}}
end

def diff_year_tag_color(diff_year)
  # color gradation depending on diff_year
  # diff_year==0(now): "success" in Bootstrap <-> diff_year==10(10 years ago): yellow
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

get '/' do
  @tags = Tag.order("num_articles desc").all
  @colors = @tags.map {|tag| diff_year_tag_color(diff_year(tag.created_at))}
  @sort_key = :article
  @searched_by = 'all'
  erb :index
end

get '/sortby_name' do
  @tags = Tag.order("name asc").all
  @colors = @tags.map {|tag| diff_year_tag_color(diff_year(tag.created_at))}
  @sort_key = :name
  @searched_by = 'all'
  erb :index
end

get '/sortby_year' do
  @tags = Tag.order("created_at asc").all
  @colors = @tags.map {|tag| diff_year_tag_color(diff_year(tag.created_at))}
  @sort_key = :year
  @searched_by = 'all'
  erb :index
end

get '/ranking/*' do |tag_name|
  @tag = tag_name
  @oldest_article = Article.where(tag1: @tag).order("num_likes desc").all[0]
  if @oldest_article.nil?
    erb :not_found
  else
    @diff_year = diff_year(@oldest_article.created_at)
    @notation_color = diff_year_notation_color(@diff_year)
    erb :ranking
  end
end

get '/about' do
  erb :about
end

get '/search_tags' do
  @tags = Tag.where('name like ?', "%#{params[:inputTagName]}%").order("name asc").all
  @colors = @tags.map {|tag| diff_year_tag_color(diff_year(tag.created_at))}
  @sort_key = :name
  @searched_by = %Q{contains "#{params[:inputTagName]}"}
  erb :index
end
