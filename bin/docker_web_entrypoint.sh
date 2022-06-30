#!/bin/bash

yarn
bundle install
[ -x tmp/pids/service.pid ] && rm tmp/pids/server.pid
bundle exec rails server -b 0.0.0.0
