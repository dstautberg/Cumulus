set APP_ENV=test
call bundle exec jruby db/setup.rb
call bundle exec jruby -S rspec test/rspec
