export APP_ENV=test
#export JRUBY_OPTS=--1.9
mkdir -p db
bundle exec ruby bin/db_setup.rb
bundle exec rspec test/rspec
