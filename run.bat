#set JRUBY_OPTS=--1.9
call pik 193
bundle exec call jruby -r config/environment -e "Main.run"
