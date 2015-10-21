
default['postgres']['user']                    = 'postgres'
default['postgres']['group']                   = 'postgres'
default['postgres']['service']                 = 'postgres'

# These will only be set if the cookbook is the first to create the postgres user
default['postgres']['home']                    = '/var/pgsql'
default['postgres']['user_shell']              = '/usr/bin/pfksh'

default['postgres']['start_service']           = true

                                               # VERSION_ABBR is the major/minor version, ie 92 for 9.2.1
                                               # Patch version changes in PG are binary swappable
default['postgres']['data_dir']                = '/var/pgsql/data%VERSION_ABBR%'
# Do not use a globally-used directory such as /var/log, as ownership is changed
# to allow writing by the postgres user
default['postgres']['log_file']                = '/var/log/postgres-%VERSION%/stderr.log'
default['postgres']['prefix_dir']              = '/opt/local/postgres-%VERSION%'
default['postgres']['version']                 = '9.4.5'
default['postgres']['remote_tar']              = 'http://ftp.postgresql.org/pub/source/v%VERSION%/postgresql-%VERSION%.tar.gz'

default['postgres']['client']['install_via']   = 'package'  # package or source
default['postgres']['client']['version']       = '9.4.5'
default['postgres']['client']['packages']      = %w(postgresql92-client)

default['postgres']['config']['encoding']                   = 'UTF8'
default['postgres']['config']['locale']                     = 'en_US.UTF-8'

default['postgres']['config']['stats_temp_directory']       = '/tmp/pg_stats_temp_directory'

# shared_buffers_mb will be automatically set to 25% of available RAM, up to 8Gb
# unless specified explicitly. cache size is auto-set to 70% of available RAM.
default['postgres']['config']['shared_buffers_mb']          = nil
default['postgres']['config']['effective_cache_size_mb']    = nil

default['postgres']['config']['max_connections']            = 400

default['postgres']['config']['checkpoint_segments']        = 64
default['postgres']['config']['checkpoint_completion_target'] = 0.9
default['postgres']['config']['checkpoint_timeout']         = '5min'

# Change this to a larger value to keep more WAL logs. The number of segments defines
# how far behind a replica can fall and then still catch up to the master. Each segment is 16Mb.
default['postgres']['config']['wal_keep_segments']       = 128

# These below have been tuned for PostgreSQL on Joyent SmartOS
default['postgres']['config']['temp_buffers_mb']         = 8
default['postgres']['config']['work_mem_mb']             = 8
default['postgres']['config']['maintenance_work_mem_mb'] = 16
default['postgres']['config']['random_page_cost']        = 2.0 # tuned for SmartOS

# -1 disables, otherwise number of milliseconds for slow query log
default['postgres']['config']['log_min_duration_statement_ms'] = 50
default['postgres']['config']['log_destination']         = 'stderr'
# suggested prefix for pgfouine compatibility (not yet verified)
default['postgres']['config']['log_line_prefix']         = ''

# Timeouts (nil to disable, or an integer in milliseconds)
default['postgres']['config']['statement_timeout'] = nil
default['postgres']['config']['lock_timeout'] = nil

# autovacuum settings
# ---------------------------------------------------------------------------------------------------------------------
default['postgres']['config']['autovacuum_enabled']  = true  # boolean
# Increase these if you are able to run daily manual 'vacuum analyze',
# or keep them at defaults otherwise.
default['postgres']['config']['autovacuum_vacuum_scale_factor']  = '0.2'  # default is 0.2, 20% of table
default['postgres']['config']['autovacuum_analyze_scale_factor'] = '0.1'  # default is 0.1, 10% of table
default['postgres']['config']['autovacuum_max_workers'] = 3
default['postgres']['config']['autovacuum_vacuum_cost_delay'] = '20ms'
default['postgres']['config']['autovacuum_vacuum_cost_limit'] = '-1'

default['postgres']['config']['autovacuum_freeze_max_age'] = '200000000' # # maximum XID age before forced vacuum (change requires restart)
default['postgres']['config']['vacuum_freeze_min_age']     = '50000000'
default['postgres']['config']['autovacuum_naptime']     = '1min'

# async writes settings
# ---------------------------------------------------------------------------------------------------------------------
default['postgres']['config']['wal_buffers']       = '-1'     # set to 32MB for more buffering
default['postgres']['config']['wal_writer_delay']  = '200ms'  # can be up to 32MB

# Script created by Chef to wrap archive logic. You should not need to edit this.
default['postgres']['config']['archive_script']    = '/opt/local/bin/pg_archive_wal_logs'
# Script that you can write in order to enable archiving. WAL archiving is a noop if this script does not exist,
# so you can change archive strategy without having to restart postgres.
default['postgres']['config']['local_archive_script']  = '/opt/local/bin/pg_archive_wal_logs.local'

default['postgres']['config']['archive_mode']      = 'on'
default['postgres']['config']['archive_command']   = "#{node['postgres']['config']['archive_script']} %p %f"
default['postgres']['config']['archive_timeout']   = 0

default['postgres']['config']['bgwriter_lru_maxpages'] = 100

default['postgres']['config']['fsync_enabled'] = true
default['postgres']['config']['wal_sync_method'] = 'fsync'

# When off, there can be a delay between when success is reported to the client and when the transaction is really
# guaranteed to be safe against a server crash. (The maximum delay is three times wal_writer_delay.)
default['postgres']['config']['synchronous_commit'] = 'on'

default['postgres']['config']['full_page_writes_enabled'] = true

# A nonzero delay can allow more transactions to be committed with only one flush operation, if system load is high enough
# that additional transactions become ready to commit within the given interval. But the delay is just wasted if no
# other transactions become ready to commit.
default['postgres']['config']['commit_delay']       = 0
default['postgres']['config']['commit_siblings']    = 5

# ---------------------------------------------------------------------------------------------------------------------


# Settings for the replicas
default['postgres']['config']['max_standby_streaming_delay']   = '30s'
default['postgres']['config']['hot_standby_feedback_enabled']  = true


default['postgres']['config']['listen_port']             = 5432

# User either list_addresses (array of IPs) or listen_interfaces, but not both.
default['postgres']['listen_addresses']                  = []
# 'bind_privateaddress' finds the first RFC1918 address using the ipaddr_extensions gem
default['postgres']['bind_privateaddress']               = true
default['postgres']['bind_publicaddress']                = false

default['postgres']['connections']  = {
    '127.0.0.1/0' => 'trust'
}
default['postgres']['replication']  = {
    '127.0.0.1/0' => 'trust'
}

