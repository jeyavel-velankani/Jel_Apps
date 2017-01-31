## Nov 2
* Opsworks walkthrough call tomorrow
* Velankani to fix sponsor login issue.. without machine id, it gives internal server error. Check the admin apis too since it too has machine id.
* Luke to email the request details about adding sponsor specified id to the retrieve api's response. Velankani to analyze the efforts involved and it would be prioritised after the current bucket items.
* API Handlers needed for all APIs (QM and AuthServer) in the design docs. Velankani to analyze the efforts involved with this.

status:
* cloudformation issue fixed for bastion
* kapil working on Authserver HLR module
* saikat working on minor QM issues - sdx_mno_rating

* working through monit


## Oct 27
Agenda
* Cloudformation
* Design Docs
* AuthServer FS3 simple module
* QM Withdraw API

* Karthik to check dynamodb dashboard during load testing
* Prasanna - break ice with Martin and let him know when you are available next week
* Prasanna/Karthik - walkthrough the Opsworks docs on Wednesday to help karthik implement the opsworks stack manually
* Sourangshu to set up the above call on Wednesday
* Velankani to come up with an approach (next week) to split QM to separate parts
* Sourangshu to intimate Luke about setting calls next week


Items deferred from October Bucket:
# Bucket A
* admin api - update sponsorship
* subscriber level parameters - moved out of scope. They don't yet have a design for this

# Bucket B
* Separate Sponsor/Subscriber QMs - Luke said just a document explaining how this can be done is enough. We might have to check if it is technically feasible, internally.
* lockdown admin interface - same as above
* HA testing - Karthik to do this after the Opsworks wednesday call
* Performance testing - Both the teams try various things to reach a baseline
* Elasticache on RDS - moved out of scope. Need docs explaining this
* Multi-Region Proto - moved out
* DB Upgrade/Rollback process - I'll explain this as part of Opsworks walkthrough
* Auto Scaling Config and Testing - we won't be doing it. Their devops most probably
* AWS Metrics - their devops
* Monit integration - moved to next week

# Bucket C
* Code walkthrough - scheduled upcoming weeks

 
 



## Oct 24
Agenda
* FS3 discussion
* withdraw api clarification
* 2FA in dev.net server clarification

current MNOs all deny roaming.

if roaming == whatever, return true
if roaming == on, return false
both depending on MNO

m1:
if rs is undetermined, deny
m2:
if rs is undetermined, allow
rest:
hlr service or api

## Oct 20
* In tomorrow's release:
  - deploy to Opsworks, dev.net environments
  - send the Bastion Server details
  - send the new log format as sample
  - send also the items not part of the release in the '1' priorities
  - ec2 instance and RDS instance - upgrade them to m3.medium in the Opsworks stack
  - enable the 3 adhoc delete apis after moving them to the admin namespace. Add instructions on how to use the APIs.
  - redirect_url in register api response - Ron had requested it. We'll evaluate this internally tomorrow and if we can accomodate the change tomorrow after testing thoroughly, we will.

* Sourangshu and Luke to schedule walkthroughs next week.

* Separate discussion with Luke about AuthServer FS3, on early Monday morning.

* Tata to look into the RDS Usage metrics to see if performance is affected


## Oct 18
* Tata: Admin APIS - Luke to get back on the necessity and urgency of some of the APIs.
* Tata: In logs, show backtrace as is, and not concatenate it with "\n". Do this change after Luke gets back with clarification from their devops team.

* Velankani: Move the existing adhoc Admin APIs to admin section. (code change question: there's no currently signed in subscriber or sponsor. So all will be deleted. Is that fine?)
* Velankani: Get AuthServer FS3 queries clarified in a separate call.
* Velankani: Opsworks Docs: Qm and Auth
* Velankani: Send the Design Docs preview. Email them the details of the Notes Repo.
* Velankani: Add migration details in the Opsworks doc.

## Oct 13
### What was done this week:
* CF work going on
* ReportServer work going on

### Questions:
* RS: we are assuming 1000 records per csv file
* RS: S3 CSV files, will they be consumed and deleted by billing guys?
* RS: start time/end time as params in opsworks?
### Velankani side deliverables
* Opsworks Doc
* Deploy QM to .net dev server and Opsworks. Deploy RS to .net dev server.
### Tata side deliverables
* Admin API specs
* Topdown API spec

## Oct 6
### What was done this week:
* deactivated api fix
* topic api change mentioned in last test results
* additional testcases in QM to increase test coverage %
* many refactorings suggested by the code quality rubocop tool (still in progress)
* Report Server - Created a new Opsworks stack (Prod-Bastion), and was able to successfully deploy the RS code there via custom chef cookbook
* Installed newrelic and tried it out in dev mode
* Tried out a performance AB test: jbuilder vs AModel Serialisation for generating json for http responses

### Question:
* AuthServer September featuresets: HLR Lookup, details needed
* Roughly how much sponsorships a subscriber might have

### Call notes:
#### Velankani side deliverables
* Send Karthik details about Report Server details in dev server
* Most important for Oct: Cloud Formation template
* Opsworks and Code documentation
* Splitting QM to 3 parts (not immediate. in Oct 2nd week)
* Send Luke frequent emails about our ongoing performace testing
* See if we ourselves can get the 14-day-trial version of Newrelic without paying anything upfront (or giving credit card details)

#### Tata side deliverables
* Updated API docs for topdown/admin apis, and subscriber-level params
* multiple machine_ids support - design doc for that
* AuthServer FS 3,4. Luke to get back on that
* 2FA ON Mode details

## Oct 5

Optimisation Areas to Explore:
* check mysql connection pool
* dynamo db ways - sidekiq, delayed_jobs - redis and mysql - pros and cons

* Velankani to make this state machine change - only 1 change to implement -> deactivate
* Velankani to make tasks out of these items and get these done on priority
* Velankani to send them the documentations: Opsworks Infrastructure and Configuration, and QM/AuthServer Code Documentation as Detailed Design Guidelines.
* Velankani to send log details email to Luke with all details (even the differences)


* Karthik/Luke to come up with a baseline tests for the current version in dev.net before making the delayed_jobs change
* Karthik to send the application log at the time the 503 Service Unavailable Error happened.

## Oct 4
* QM and AuthServer - eventually in different VPCs
* open HTTP 80 in QM ELB too (done already)
* QM's ELB url is mapped to sqm-dev.spondata.com. So test it with. Also change AuthServer's opswork stack's QM URL to use this new url. (done already. Opsworks AuthServer is now able to talk to Opsworks QM instance for the CFSU api)
* Keep dev server in sync with Opswork codebase (done already)
* Velankani is working on implementing code quality tools (need to document them as well)

* Send Luke the logformat (how it were setup too, sample log lines)
* Send a diagram of the architecture to Luke. Send the link of Scenario 2
* Document the code coverage tools usage

* Luke to get back on when to change EC2 instance type in the Opsworks stack
* Luke to get back with JMeter scripts
* Luke to get back on these: multiple machine ids and return code behaviour for consumed/expired transitions

## Sep 29 - Weekly Call with Luke
(fixed presentation data related issues mentioned by Luke in email. Will go in tomorrow's drop)

Priority for tomorrow is manual opsworks setup with ELB (for QM, if possible for AuthServer too). Focus on generating CloudFormation templates after this is approved.

AWS Opsworks Architecture:
(step 1)
* introduce loadbalancer before QM and Authserver Opsworks
* share elb url to Luke, so he can point that url to a domain
(step 2)
* add ssl certificates to ELB (only for QM, not for Authserver)
* for October: remove QM elastic ips, and put them to the NAT.
* Luke to talk to devops team about the log file issue (not showing loglevels)

* Tomorrow's testing will be on Opsworks QM


## Aug 12 - API guidelines discussion (in Protocol Design Doc)

* retrieve-sponsorships
even if spship already is 'consumed' or 'expired', return them.
if invalid spship, or other subscriber's spship, then just log error, but return spships.

* activate-sponsorships
if invalid ids, we would return error, but would have handled valid spship activations. (same above)

- in quota_reports validation, add a condn for "quota_usage_reported == quota_total" (not in doc)

* if deactivate reason is NOT the 3 defined, keep state as deactivated, just log it, and use the prev errorCode to return

* if spship is already expired or consumed, update the quota_reports, but set state accordingly

- quota_bytes_total, and quota_bytes_per_user are currently the same

- create-sponsorship and topup apis will send details in MB, but we have to convert it to bytes - MB to Bytes -> 1024 * 1024


