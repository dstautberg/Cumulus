APP_ENV = ENV["APP_ENV"] || "development"
require "rubygems"
require "java"
require "sequel"
require "logger"
require "socket"
require 'thread'

AppLogger = Logger.new("log/#{APP_ENV}.log")

DB = Sequel.connect("jdbc:sqlite:db/#{APP_ENV}.sqlite3")

Dir.glob("app/**/*.rb").sort.each do |f|
  require f
end

require_relative APP_ENV
