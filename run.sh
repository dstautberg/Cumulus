#export JRUBY_OPTS=--1.9
bundle
bundle exec ruby -r ./config/environment -e "Main.run"
