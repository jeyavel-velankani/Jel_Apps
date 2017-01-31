# Queries

* In 'subscriber login' api, based on what request param(s) the entity retrieval is done,
and based on what request param(s), the authentication is done?
Currently, we are not authenticating based on any request param.
We are simply searching the db for a subscriber that has matching values for *ALL* of these values that come from request:
  1) auth_token
  2) machine_id
  3) subscriber_info (here, based on 'subscriber_type', we are only searching using the relevant fields. eg: if type is 'unrestricted msisdn', we ignore control_app_id and user_id)

  To add context: In sponsor login api, we first get the sponsor from the db based on the username that comes in the request (retrieval phase).
And then we check if that user's password is the same as the password passed in the request (authentication phase).

In 'subscriber login', do we have such phase distinctions? Or do we simply search the db for a matching record with all the request params (except request id) as search fields?

Without this phase distinction, we'd not be able to give out specific error codes like: 'invalid machine id', 'invalid auth_token' etc. We can only give generic code: 'invalid subscriber info'.

* how to distinguish partial/full subscriber registration at DB level? Can we have another field in 'subscribers' table?

* In 'register' api, with the subscriber_sdx_app_id, should we check if there's a control app present already in our DB with that id?

* In v0.7 QM API doc, appendix B.6 for 'subscriber_info' is not yet present. Need this to determine the required and optional parameters.
