set APP_ENV=test
rem set JRUBY_OPTS=--1.9
call pik 193
call bundle exec ruby script/db_setup.rb
call bundle exec rspec test/rspec
