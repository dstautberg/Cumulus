require_relative "../config/environment"
require "factory_girl"

# Patch to make Sequel work with Factory Girl.
class Sequel::Model
  def save!
    save
  end
end

Dir.glob("test/factories/**/*.rb").sort.each {|f| require f }
