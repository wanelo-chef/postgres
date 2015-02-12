#
# Cookbook Name:: postgres
# Recipe:: client_source
#
# Copyright 2013, Wanelo, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'postgres::build'

pg_basedir = node['postgres']['prefix_dir'].gsub(/%VERSION%/, node['postgres']['client']['version'])

%w( clusterdb createdb createlang createuser dropdb droplang
    dropuser ecpg initdb pg_basebackup pg_config pg_controldata
    pg_ctl pg_dump pg_dumpall pg_receivexlog pg_resetxlog
    pg_restore pg_upgrade pg_bench postgres psql reindexdb
    vacuumdb ).each do |cmd|
  link "/opt/local/bin/#{cmd}" do
    to "#{pg_basedir}/bin/#{cmd}"
  end

end

%w( libpq.a libpq.so libpq.so.5 libpq.so.5.6 ).each do |lib|
  link "/opt/local/lib/#{lib}" do
    to "#{pg_basedir}/lib/#{lib}"
  end
end