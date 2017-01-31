# Copyright (C) 2016 Tata Communications, Ltd. All rights reserved. 

# Steps to deploy the app in a server

* 'sudo apt-get update'


# Install Ruby using chruby:

First of all, we're going to run sudo apt-get update so that we have the latest sources on our box so that we don't run into any package-related issues, such as not being able to install some packages.

Next, we'll run another command which will install the essential building tools that will be used to install Ruby:

* 'sudo apt-get install build-essential'

And now we're ready to install ruby-install.
ruby-install
The installation instructions can be found on the README of ruby-install, but I'll repeat them here so you don't have to go over there:

* 'wget -O ruby-install-0.6.0.tar.gz \
  https://github.com/postmodern/ruby-install/archive/v0.6.0.tar.gz
tar -xzvf ruby-install-0.6.0.tar.gz
cd ruby-install-0.6.0/
sudo make install'

First we fetch the ruby-install file, extract it into a directory, then make it. You can verify that these steps have worked by running the following command:

* '$ ruby-install -V'

If you see this, then you've successfully installed ruby-install:

* 'ruby-install: 0.6.0'

# Ruby
Our next step is to install Ruby itself, which we can do with this command:

* 'ruby-install --latest ruby 2.3.1'

This command will take a couple of minutes, so grab your $DRINKOFCHOICE and go outside or something. Once it's done, we'll have Ruby 2.3.1 installed. In order to use this Ruby version, we'll need to install chruby as well. The instructions can be found in chruby's README too, but I will reproduce them here:

* 'wget -O chruby-0.3.9.tar.gz \
  https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz
  tar -xzvf chruby-0.3.9.tar.gz
  cd chruby-0.3.9/
  sudo make install'

After this has been installed, we'll need to load chruby automatically, which we can do by adding these lines to your 

* 'shells configuration file using the following command:
    cat >> ~/.$(basename $SHELL)rc <<EOF
    source /usr/local/share/chruby/chruby.sh
    source /usr/local/share/chruby/auto.sh
    EOF'

In order for this to take effect, we'll reload the shell

* 'exec $SHELL'

Alternatively, opening a new terminal tab/window will do the same thing.
To verify that 'chruby' is installed and has detected our Ruby installation, runchruby. If you see this, then it's working:

* 'ruby-2.3.0'

Now we need to make that Ruby the default Ruby for our system, which we can do by creating a new file called ~/.ruby-version with this content:

* 'ruby-2.3.0'

This file tells chruby which Ruby we want to use by default. To change the ruby version that we're using, we can run chruby ruby-2.3.1 for example -- assuming that we have Ruby 2.3.0 installed first!
Did this work? Let's find out by running ruby -v:
ruby 2.3.1(2015-12-25 revision 53290) [x86_64-linux]


##Install Bundler gem:
* 'gem install bundler'


##Instal MYSQL Server:
* 'sudo apt-get install mysql-server'

##MySql Client plugin:
* 'sudo apt-get install libmysqlclient-dev'

##Node.js:
* 'sudo apt-get install nodejs'


##Login to mysql server and create database quota_management_staging:(only first time):

* 'mysql -u root -p'
* 'CREATE DATABASE quota_management_staging;''


##Deploy you app from the master branch(keep master branch as uptodate):
Below command will deploy the app from git and will configure it automatically

* 'cap staging deploy'


##First time need to do below task:(this files contain the databasename , username, password,etc..).
Copy file database.yml , secrets.yml file and place it in the server apps/sdx_qm/shared/config folder.


##Install Passenger Gem:

* 'gem install passenger ''

##Install Passenger and Nginx
The preferred method to install Passenger in the past was using a generic installation via RubyGems (passenger-install-nginx-module).
However, you can now install Passenger on Ubuntu with the Advanced Packaging Tool (APT), which is what we'll be using. In this manner, the installation and — even more importantly — the update process for Passenger with Nginx, is really simple.
First, install a PGP key:

* 'sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7'

Create an APT source file (you will need sudo privileges):

* 'sudo nano /etc/apt/sources.list.d/passenger.list'

And insert the following line in the file:

* 'deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main'

Press CTRL+x to exit, type y to save the file, and then press ENTER to confirm the file location.
Change the owner and permissions for this file:

* 'sudo chown root: /etc/apt/sources.list.d/passenger.list'
* 'sudo chmod 600 /etc/apt/sources.list.d/passenger.list'

Update the APT cache:

* 'sudo apt-get update'

Finally, install Passenger with Nginx:
sudo apt-get install nginx-extras passenger
This step will overwrite our Ruby version to an older one. To resolve this, simply remove the incorrect Ruby location and create a new symlink to the correct Ruby binary file:

* 'sudo rm /usr/bin/ruby'
* 'sudo ln -s /usr/local/bin/ruby /usr/bin/ruby'

##Set Up The Web Server
Open the Nginx configuration file: 

* 'sudo nano /etc/nginx/nginx.conf'

Find the following lines, in the http block:

[#passenger_root /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini;]
[#passenger_ruby /usr/bin/ruby;]

Uncomment both of them. Update the path in the passenger_ruby line. They should look like this:

* 'passenger_root /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini;'

* 'passenger_ruby /usr/local/bin/chruby-wrapper; '

Save and exit the file.


##Deploying with Passenger - how to create above passenger_ruby path

chruby is easy to wire up with Passenger. Using the same tool (chruby) both in production and development is often useful.

* '/etc/profile.d/chruby.sh' (owned by root)

* 'if [ -n "$BASH_VERSION" ] || [ -n "$ZSH_VERSION" ]; then
  source /usr/local/share/chruby/chruby.sh

  # auto-switching is used for login shells, but not by
  # passenger or cron jobs. See `chruby-wrapper` for details.
  source /usr/local/share/chruby/auto.sh
fi'

* '/usr/local/bin/chruby-wrapper' (owned by root; make it executable)

# copy below configuration and paste it in the /usr/local/bin/chruby-wrapper file and save it


#--------START---------------------
#!/bin/bash
source /usr/local/share/chruby/chruby.sh
source /usr/local/share/chruby/auto.sh

# calling `chruby_auto` after loading is needed in certain cases
# https://github.com/postmodern/chruby/issues/258#issuecomment-44897142
chruby_auto

# Adjustment if the deploy-user differ from `passenger_user`
#
# With chruby, gems are either installed in '/opt/rubies/[...]' when running as root,
# otherwise under '$home/.gem/[...]'. When bundler is run by `deploy-user` (could be a different name) 
# we need to update the paths so the runner of this wrapper can find them.
# 
# This is *not* needed if the user installing the gems is the same as `passenger_user`.
# Must adjust $GEM_HOME, $GEM_PATH and $PATH (for ./bin in gems). $GEM_ROOT can be left unchanged.
#
# UNCOMMENT IF NEEDED
# deploy_user_home=$(echo ~deploy-user)

# override values set by chruby
# https://github.com/postmodern/chruby/blob/a44c03/share/chruby/chruby.sh#L57
export GEM_HOME="$deploy_user_home/.gem/$RUBY_ENGINE/$RUBY_VERSION"
export GEM_PATH="$GEM_HOME:$GEM_PATH"
export PATH="$GEM_HOME/bin:$PATH"

# original call
exec "ruby" "$@"
[path/to/configuration]/nginx.config
#---------------END--------------------------------



##Deploy
At this point you can deploy your own Rails application if you have one ready. If you want to deploy an existing app, you can upload your project to the server and skip to the /etc/nginx/sites-available/default step.
We need to disable the default Nginx configuration. Open the Nginx config file:

* 'sudo nano /etc/nginx/sites-available/default'

Find the lines:

listen 80 default_server;
listen [::]:80 default_server ipv6only=on;
Comment them out, like this:
# listen 80 default_server;
# listen [::]:80 default_server ipv6only=on;

Save the file.

##Now, create an Nginx configuration file for our app:
* 'sudo nano /etc/nginx/sites-available/testapp'

Add the following server block. The settings are explained below.

* 'server {
  listen 80 default_server;
  server_name www.mydomain.com;
  passenger_enabled on;
  passenger_app_env development;
  root /home/rails/testapp/public;
}'

In this file, we enable listening on port 80, set your domain name, enable Passenger, and set the root to thepublic directory of our new project. The root line is the one you'll want to edit to match the upload location of your Rails app.
If you don't want to assign your domain to this app, you can skip the server_name line, or use your IP address.
To test our setup, we want to see the Rails Welcome aboard page. However, this works only if the application is started in the development environment. Passenger starts the application in the production environment by default, so we need to change this with the passenger_app_env option. If your app is ready for production you'll want to leave this setting out.
Save the file (CTRL+x, y, ENTER).

Create a symlink for it:

* 'sudo ln -s /etc/nginx/sites-available/testapp /etc/nginx/sites-enabled/testapp'

##Restart Nginx:
* 'sudo nginx -s reload'

Now your app's website should be accessible. Navigate to your Droplet's domain or IP address:

* 'http://droplet_ip_address'


