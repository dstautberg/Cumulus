rem set JRUBY_OPTS=--1.9
call pik 193
call bundle
call bundle exec ruby -r "./app/main" -e "Main.run"
