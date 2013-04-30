#
# Cookbook Name:: postgres
# Recipe:: server
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


include_recipe 'ipaddr_extensions::default'
include_recipe 'postgres::build'

case node['platform']
  when 'smartos'
    available_ram = `prtconf -m`.chomp.to_i
end

shared_buffers_mb       = [12000, (available_ram * 0.25).to_i].min
effective_cache_size_mb = (available_ram * 0.95).to_i - shared_buffers_mb

node.default['postgres']['config']['shared_buffers_mb']       = shared_buffers_mb
node.default['postgres']['config']['effective_cache_size_mb'] = effective_cache_size_mb

version       = node['postgres']['version']                # eg 9.2.1
version_abbr  = version.split('.').slice(0..1).join        # eg 92
version_num   = version.split('.').join                    # eg 921

config        = node['postgres']['config']
os_user       = node['postgres']['user']
os_group      = node['postgres']['group']
service_name  = node['postgres']['service'] + version_num  # eg postgres921
data_dir      = node['postgres']['data_dir'].gsub(/%VERSION_ABBR%/, version_abbr)
log_file      = node['postgres']['log_file'].gsub(/%VERSION%/, version)
bin_dir       = node['postgres']['prefix_dir'].gsub(/%VERSION%/, version) + '/bin'
shell_script  = "/opt/local/share/smf/method/postgres-#{version}.sh"

# create postgres user if not already there
user os_user do
  comment 'PostgreSQL User'
  home node['postgres']['home']
  shell node['postgres']['user_shell']
  action :create
end

group os_group do
  action :create
end

directory config['stats_temp_directory'] do
  owner os_user
  group os_group
end

directory '/opt/local/share/smf/method' do
  recursive true
  action :create
end

directory File.dirname(data_dir) do
  recursive true
  owner os_user
end

directory File.dirname(log_file) do
  recursive true
  owner os_user
  group os_group
end

execute "running initdb for data dir #{data_dir}" do
  command "#{bin_dir}/initdb -D #{data_dir} -E '#{config['encoding']}' --locale='#{config['locale']}'"
  user os_user
  not_if { File.exists?(data_dir)}
end

template shell_script do
  source 'postgres-service.sh.erb'
  mode '0700'
  owner os_user
  group os_group
  notifies :reload, "service[#{service_name}]"
  variables(
      'bin_dir' => bin_dir,
      'data_dir' => data_dir,
      'log_file' => log_file
  )
end

template "#{data_dir}/pg_hba.conf" do
  source 'pg_hba.conf.erb'
  owner os_user
  group os_group
  mode '0600'
  notifies :reload, "service[#{service_name}]"
  variables('connections' => node['postgres']['connections'],
            'replication' => node['postgres']['replication']  )
end

node.default['postgres']['listen_addresses'] << '127.0.0.1'
node.default['postgres']['listen_addresses'] << node['privateaddress'] if node['postgres']['bind_privateaddress']
node.default['postgres']['listen_addresses'] << node['ipaddress'] if node['postgres']['bind_publicaddress']

template "#{data_dir}/postgresql.conf" do
  source 'postgresql.conf.erb'
  owner os_user
  group os_group
  mode '0600'
  notifies :reload, "service[#{service_name}]"
  variables config.to_hash.merge('listen_addresses' => node['postgres']['listen_addresses'])
end

resource_control_project 'postgres' do
  comment 'PostgreSQL'
  users os_user
end

smf service_name do
  user os_user
  group os_group
  project 'postgres'
  start_command "#{shell_script} start"
  stop_command "#{shell_script} stop"
  refresh_command "#{shell_script} refresh"
  start_timeout 60
  stop_timeout 60
  refresh_timeout 60
end

service service_name do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
  not_if { system("ps -ef | grep '[p]ostgres -D'") || system("svcs -a | grep postgres | grep online")   }
end
