# Copyright (C) 2016 Tata Communications, Ltd. All rights reserved. 

#Steps for execute SimpleCov code coverage analysis tool

#1.Add SimpleCov to your Gemfile and bundle install:
* gem 'simplecov', :require => false, :group => :test

#2.Load and launch SimpleCov at the very top of your test/test_helper.rb
* require 'simplecov'
* SimpleCov.start 'rails'

#3.Run application tests cases
* navigate to application root path cd ...\SDX_v2_QuotaManager and run the below command

##Specified test file to run
* bundle exec rails test test/integration/sponsor_apis/ test/integration/subscriber_apis/ test/integration/auth_apis/ test/integration/call_data_record/ test/integration/claimed_and_unclaimed_bytes/

##Run all test cases
* bundle exec rails test

#4.open up coverage/index.html in your browser and check out what you've missed so far.
* Coverage report will generate in application coverage/index.html if test cases executed successfully
* Open the coverage report and check out what you've missed so far