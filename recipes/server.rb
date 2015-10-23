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

include_recipe 'postgres::build'

version = node['postgres']['version']

postgres_initdb "initialize db for postgres #{version}" do
  version version
  action :init
end

postgres_service version do
  version version
  notifies :enable, "postgres_service[#{version}]" if node['postgres']['start_service']
  notifies :reload, "postgres_service[#{version}]"
end
