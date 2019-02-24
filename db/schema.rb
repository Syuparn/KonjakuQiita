# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_02_24_061047) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "articles", force: :cascade do |t|
    t.string "name"
    t.integer "num_likes"
    t.string "tag1"
    t.string "tag2"
    t.string "tag3"
    t.string "tag4"
    t.string "tag5"
    t.string "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "author_id"
    t.string "author_name"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.integer "num_articles"
  end

end
