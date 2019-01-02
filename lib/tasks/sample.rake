# require is relative to root path
require './models/tag'

namespace :sample do
  desc "It is sample task!!"
  task :say_hello do
    puts 'Hello!! Rake!!'
  end

  desc "make new tag data in db"
  task :create_tag do
    Tag.delete_all
    # mock data
    results = [['Ruby', 10], ['Python', 12], ['PHP', 4], ['js', 2]]
    results.each do |result|
      Tag.create(name: result[0], num_likes: result[1])
    end
  end
end
