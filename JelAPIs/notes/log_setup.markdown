# Copyright (C) 2016 Tata Communications, Ltd. All rights reserved. 

# Syslog Log setup (local and remote)

## Local
This doc tells how to make rails use the (r)syslog daemon for logging.


* In the corresponding env config files:
  # Logging
  require 'syslog/logger'
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Logstash.new
  config.lograge.custom_options = ->(event) do
    exceptions = %w(controller action format id)
    {
      time: event.time,
      params: event.payload[:params].except(*exceptions)
    }
  end
  config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new('sdx_qm'))


* sudo vim /etc/rsyslog.d/sdx_qm.conf (owner: root)
    # /etc/rsyslog.d/sdx_qm.conf

    if $programname == 'sdx_qm' then /var/log/sdx_qm.log

* Don't create this file: /var/log/qm.log. rsyslog will automatically create it after it is restarted.
* restart rsyslog using 'sudo service rsyslogd restart' or 'sudo killall -HUP rsyslogd'. Also restart the rails app to be sure.

## Remote
