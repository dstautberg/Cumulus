rem set JRUBY_OPTS=--1.9
call pik 193
call bundle
set APP_ENV=production
rem TEMPORARY:
del log\production.log
call bundle exec ruby -r "./app/main" -e "Main.run"
