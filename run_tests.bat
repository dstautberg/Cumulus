set APP_ENV=test
rem set JRUBY_OPTS=--1.9
call bundle exec ruby bin/db_setup.rb
call bundle exec rspec test/rspec
