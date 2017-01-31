# Copyright (C) 2016 Tata Communications, Ltd. All rights reserved. 

# Steps to run this rails app locally


## Requirements
* The ruby version required by the app needs to be installed. The version required is mentioned in the file `.ruby-version`. It's current value is `2.3.1`. See steps below to install ruby.
* Install the [Postman app](https://www.getpostman.com/) Install the standalone app rather than the chrome app if you can.
Postman is an easy way to test APIs. The `quota_management.postman_collection.json` file can be imported into your Postman app. It currently has all the api requests saved in a collection `quota_management`.
* mysql server. The version I use for local development is currently: `mysql  Ver 14.14 Distrib 5.6.30, for debian-linux-gnu (x86_64) using  EditLine wrapper`. Yours need not be exactly this, but a closer version can suffice.


## Installing Ruby

The following 2 guides are both from the same guy, Ryan Bigg, a popular face in Rails circle.
The guides are updated for 2016. Pick one depending on your OS.

The guide not only cover installing ruby, but certain requirements around database adapters(install only for mysql) and xml parsing libraries.

The guide also covers installing rails. But **DO NOT INSTALL RAILS** from the guide. We'll do that below.

The guide covers installing ruby `2.3.0`. But currently our app uses `2.3.1`. So make sure to change this number in the relevant commands.

OS specific instructions:

* [OSX](http://ryanbigg.com/2015/06/mac-os-x-ruby-ruby-install-chruby-and-you/)
* [Ubuntu](http://ryanbigg.com/2014/10/ubuntu-ruby-ruby-install-chruby-and-you/)


## Setting up the rails app
All the commands mentioned here are run in a terminal from the app's root folder, unless otherwise specified.

### bundler
`bundler` is a gem that does dependency management in rails.

Libraries in ruby are called as *gems*.

All the gems your app (rails or non-rails) would need, are specified in the `Gemfile` present in your project's root. Running bundler (as below) would download those gems (and their dependent gems) and keep track of them along with their versions in another file called `Gemfile.lock`.

* Install bundler first. From the project's root:
`gem install bundler`

* Once it is done, run this command:
`bundle`

This will take a while as it will install all the dependent gems for this rails app, mentioned in the `Gemfile` file. If it completed successfully, you'll know it - green colored msg "Bundle complete!" will show up before the program exits.

### create databases and run migration
* rename `config/database.yml.example` to `config/database.yml`

* In this new yml file, fill in the username (usually root) and password of your local mysql server

* Run this to create the development and test databases:
`bin/rails db:create`

* Run this to run the migrations:
`bin/rails db:migrate`
This is the cmd you'll run every time you pull code. If there are any pending migrations left, they'll be run and your local db schema will be kept up-to-date.

### Run the server at localhost
 Run this to start the application server listening on port 3000:
`rails s`

If you can't use port 3000, you can specify alternative port as:
`rails s -p 3001`

For this QM app, the homepage will be blank. There's nothing to see there. All your interactions will happen through an API client like Postman.

### Running tests
Rails has automated testing support. You can find an overview [here](http://guides.rubyonrails.org/v4.2/testing.html).

* To run the whole test suite:
`bin/rails test`

* To run only the controller or model or integration tests:
`bin/rails test test/controllers/`
`bin/rails test test/models/`
`bin/rails test test/integrations/`

* To run only the tests in a specific file:
`bin/rails test test/integration/sponsor_side_apis_test.rb`

* To run only a specific test in a particular file, just append the starting line number of that test:
`bin/rails test test/integration/sponsor_side_apis_test.rb:12`

Note1: By default, rails assumes the current environment is 'development'. It is true when the rails app is run locally.
But it changes for staging, production and other environments. Depending on this, many will change: for eg: the database mentioned under the staging section will be chosen if RAILS_ENV=staging, and the initializer code present in `config/environments/staging.rb` file.
The app in the dev server runs in 'staging' env. That's why you have to prefix the command with RAILS_ENV=staging.



## Git
We try to use [Git flow](http://danielkummer.github.io/git-flow-cheatsheet/) as much as possible. So the latest code will always be on the **develop** branch. But only the (updated) **master** branch will be deployed to any non-development environment.

## Understanding Rails
The table below [this section](http://guides.rubyonrails.org/v4.2/getting_started.html#creating-the-blog-application) explains the purpose of the common files and folders you'll find in a typical rails app.

### Ruby and Rails Reference
* The official [rails guides](http://guides.rubyonrails.org/index.html) covers all topics of rails you might want to know: models, views, controllers, url routes, testing, query interface, associations, migrations, layouts, form helpers etc.

* The specific API documentation for rails specific methods can be found [here](http://api.rubyonrails.org/)

* Ruby 2.3.1's [core api](http://ruby-doc.org/core-2.3.1/)

* Ruby 2.3.1's [standard library api](http://ruby-doc.org/stdlib-2.3.1/)
