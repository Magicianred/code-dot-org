#!/usr/bin/env bash

# Entrypoint script for running unit tests within a docker container.
# Start the container using docker-compose with the unit-tests-compose.yml file in the project root.
# (See comments at top of file for how to use docker-compose.)

set -xe

export CI=true
export RAILS_ENV=test
export RACK_ENV=test
export DISABLE_SPRING=1
export LD_LIBRARY_PATH=/usr/local/lib

# start mysql
sudo service mysql start && mysql -V

eval "$(rbenv init -)"
bundle install --verbose

# set up locals.yml
echo "
bundler_use_sudo: false
properties_encryption_key: $PROPERTIES_ENCRYPTION_KEY
cloudfront_key_pair_id: $CLOUDFRONT_KEY_PAIR_ID
cloudfront_private_key: \"$CLOUDFRONT_PRIVATE_KEY\"
ignore_eyes_mismatches: true
disable_all_eyes_running: true
use_my_apps: true
use_my_shared_js: true
build_blockly_core: true
build_shared_js: true
build_dashboard: true
build_pegasus: true
build_apps: true
localize_apps: true
dashboard_enable_pegasus: true
dashboard_workers: 5
skip_seed_all: true
" >> locals.yml

# name: rake install
RAKE_VERBOSE=true mispipe "bundle exec rake install" "ts '[%Y-%m-%d %H:%M:%S]'"

# name: rake build
RAKE_VERBOSE=true mispipe "bundle exec rake build --trace" "ts '[%Y-%m-%d %H:%M:%S]'"

# unit tests
bundle exec rake circle:run_tests --trace
