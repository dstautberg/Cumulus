APP_ENV = ENV["APP_ENV"] || "development"
require "rubygems"
#require "java"
require "sequel"
require "logger"
require "socket"
require "thread"
require "timeout"
require "json"
require "securerandom"
require "fileutils"
require "sys/filesystem"
require "eventmachine"

AppLogger = Logger.new("log/#{APP_ENV}.log")

#DB = Sequel.connect("jdbc:sqlite:db/#{APP_ENV}.sqlite3")
DB = Sequel.sqlite("db/#{APP_ENV}.sqlite3", :logger => AppLogger)

$: << "." # add the current directory to the require path

Dir.glob("app/**/*.rb").sort.each { |f| require f.gsub(".rb","") }

require_relative APP_ENV
require_relative "local" # used to override configuration for a single machine
