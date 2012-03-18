require "rubygems"
require "java"
require "sequel"

APP_ENV = ENV["APP_ENV"] || "development"

DB = Sequel.connect("jdbc:sqlite:db/#{APP_ENV}.sqlite3")

Dir.glob("../app**/*.rb").sort.each do |f|
  require_relative f
end

require_relative APP_ENV
