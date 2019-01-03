# require is relative to root path
require './models/tag'

namespace :sample do
  desc "It is sample task!!"
  task :say_hello do
    puts 'Hello!! Rake!!'
  end

  desc "make new tag data in db"
  task :create_tag do
    Tag.create(name: 'Ruby', num_likes: 10)
  end

  desc "destroy tag data in db"
  task :destroy_tag do
    Tag.delete_all
  end
end
