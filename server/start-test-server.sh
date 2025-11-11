#!/bin/bash

# Load test environment
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=blescanner_test
export DB_USER=blescanner_test_user
export DB_PASSWORD=test_password
export JWT_SECRET=test_secret_key_for_local_testing_only_not_for_production
export PORT=3001
export NODE_ENV=development
export APNS_KEY_ID=dummy
export APNS_TEAM_ID=dummy
export APNS_TOPIC=com.test.app
export APNS_KEY_PATH=./config/dummy.p8
export APNS_PRODUCTION=false

# Start server
npm start
