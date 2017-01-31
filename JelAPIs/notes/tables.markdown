# Copyright (C) 2016 Tata Communications, Ltd. All rights reserved. 
# Tables (Db: SDX Quota Management Database)

## 1) Admin (table name: admins)
* id
username
encrypted_password
(other devise related fields)

## 2) Sponsor (table name: sponsors)
* id - int
* username - str64
* password - str255 (rails default string)
* machine_id - str64
* session_id - str255
= uniq index on username
#### contact info (phone, address, email etc)
* contact_name
* mailing_address
* phone
* email

## 3) Subscriber (table name: subscribers) (or users)
* id
* auth_token
* user_id_type (phone number or proprietary) (str64)
* uid (this is the `user_id` from the request) ('+123455667') (str64)
select * from spoships where user_id in (select id from subscribers where uuid = '+122345')
* phone_country_code - str3
* phone_number - str15(confirm?)

* uniq index on uuid (`user_id`)

## 4) Sponsorship (table: sponsorships)
* id
* name - str255
* sponsor_id
* user_id (actually subscriber_id) 
* obfuscated_user_id (4.1.1-6)
* mno_ids (array) (4.1.1-8)
* start_time - str32 (unix epoch time)
* end_time - str32 (unix epoch time)
* can_expire (boolean. true: can expire,  default false: can't expire)
* tracking_id (4.1.1-15)
* state - str32 (CREATED INACTIVE RETRIEVED ACTIVATED CONSUMED EXPIRED REVOKED)
* sponsorship_type - str32 (valid sponsorship types: DATA_GIFT, DATA_REWARD, CAMPAIGN)
* app_list (array of apps)(ph2)
* created_at - datetime
* updated_at - datetime

* index on sponsor_id
* index on user_id (required if wallet table not needed)

(quota related fields) (need a separate table?)
which are needed?
- (from the SRS doc)
  * total_bytes
  * remaining_bytes
  * bytes_for_control_app (4.1.2-4 ?)
- (from API doc, appendix B sample json)
  * quota_bytes_total
  * quota_bytes_per_user
  * quota_bytes_claimed
  * quota_bytes_unclaimed
  * quota_bytes_reported_used

## 5) MNO (table: mnos)
* id
* name - str64
* mcc - str3 TBD
* mnc - str3 TBD

* index on sponsorship_id

## 6) Sponsored Data Wallet (4.1.4) (not needed as this can be inferred from sponsorships table)
* id
* user_id (or subscriber_id)
* sponsorship_id

* index user_id

## sponsorships_mnos
sponsorship_id
mno_id

* index sponsorship_id
sid mnoid
1  12
1  13

## 7) apps (phase2) discuss?
id
name
description

## 8) sponsorships_apps
sid appid
