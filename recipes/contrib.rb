#
# Cookbook Name:: postgres
# Recipe:: contrib
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

version = node['postgres']['version']
src_dir = "#{Chef::Config['file_cache_path']}/postgresql-#{version}/contrib"
prefix_dir  = node['postgres']['prefix_dir'].gsub(/%VERSION%/, version)
bin_dir     = prefix_dir + '/bin'

# pg_upgrade

execute 'install pg_upgrade_support' do
  cwd "#{src_dir}/pg_upgrade_support"
  command 'make && make install'
  not_if { File.exists?("#{bin_dir}/pg_upgrade") }
end

execute 'install pg_upgrade' do
  cwd "#{src_dir}/pg_upgrade"
  command 'make && make install'
  not_if { File.exists?("#{bin_dir}/pg_upgrade") }
end

# pgbench

execute 'install pgbench' do
  cwd "#{src_dir}/pgbench"
  command 'make && make install'
  not_if { File.exists?("#{bin_dir}/pgbench") }
end

# pg_stat_statements

ruby_block 'pg_stat_statements info' do
  block do
    Chef::Log.info <<-EOL

    #################################################

    Installing pg_stat_statements contrib extension

    In order to enable this extension, log into your
    Postgres instance and run the following command:

      CREATE EXTENSION pg_stat_statements;

    #################################################
    EOL
  end
  not_if { File.exists?("#{prefix_dir}/lib/pg_stat_statements.so") }
end

execute 'install pg_stat_statements' do
  cwd "#{src_dir}/pg_stat_statements"
  command 'make && make install'
  not_if { File.exists?("#{prefix_dir}/lib/pg_stat_statements.so") }
end
