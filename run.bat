rem set JRUBY_OPTS=--1.9
call pik 193
bundle
bundle exec call ruby -r config/environment -e "Main.run"
