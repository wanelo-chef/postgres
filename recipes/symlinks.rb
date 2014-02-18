version = node['postgres']['version']
prefix_dir = node['postgres']['prefix_dir'].gsub(/%VERSION%/, version)
version_specific_bin_dir = prefix_dir + "/bin"

%w(
  clusterdb   ecpg            pg_dumpall      postgres
  createdb    initdb          pg_isready      postmaster
  createlang  pg_basebackup   pg_receivexlog  psql
  createuser  pg_config       pg_resetxlog    reindexdb
  dropdb      pg_controldata  pg_restore      vacuumdb
  droplang    pg_ctl          pg_upgrade
  dropuser    pg_dump         pgbench
).each do |cmd|
  link "/opt/local/bin/#{cmd}" do
    to "#{version_specific_bin_dir}/#{cmd}"
  end
end

# This assumes that the major version of libpq that ships with
# postgres `version` is 5. To be fixed when that is no longer
# the case.
%w(
  libpq.so libpq.so.5
).each do |lib|
  link "/opt/local/lib/#{lib}" do
    to "#{prefix_dir}/lib/#{lib}"
    not_if "test -e /opt/local/lib/#{lib}"
  end
end
