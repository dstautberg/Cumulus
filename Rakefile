require 'rspec/core/rake_task'

namespace :test do
  desc "Run rspec tests"
  RSpec::Core::RakeTask.new("rspec") do |t|
    t.pattern = "./test/rspec/**/*_spec.rb"
  end
end

desc "Run all the tests"
task :test => ["test:rspec"]
