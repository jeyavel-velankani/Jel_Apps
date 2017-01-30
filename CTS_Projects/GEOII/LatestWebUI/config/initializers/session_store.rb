# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_rails_IVIU_session',
  :secret      => '47280f6809d6ed9479e61b63f02ac00f98e4e7910cfa94bfa30a38326e5c060ccc27312dd6ddb43e187f77dc2abc29b8132b8fd439d49e922278b799eaacb7bc'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
