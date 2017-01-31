# Copyright (C) 2016 Tata Communications, Ltd. All rights reserved. 

# ER design

## Models and Relationships
* account models:
  - Admin - for CRUD ops in ActiveAdmin - Devise model
  - Subscriber
  - Sponsor - Devise model

* Sponsorship belongs_to Sponsor, User
* Quota belongs_to Sponsorship
* Sponsor
* SponsoredDataWaller (not yet defined) - collection of sponsorships assigned to a given user


## Mysql available datatypes mapped with rails
NATIVE_DATABASE_TYPES = {
:primary_key => "int(11) auto_increment PRIMARY KEY",
:string      => { :name => "varchar", :limit => 255 },
:text        => { :name => "text" },
:integer     => { :name => "int", :limit => 4 },
:float       => { :name => "float" },
:decimal     => { :name => "decimal" },
:datetime    => { :name => "datetime" },
:time        => { :name => "time" },
:date        => { :name => "date" },
:binary      => { :name => "blob" },
:boolean     => { :name => "tinyint", :limit => 1 }
}

## Pending work

