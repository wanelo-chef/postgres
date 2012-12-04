# Install PG server from sources
# Creates user if necessary
# Initializes data directory if not found

# Used to determine what IP addresses to bind
def listen_addr_for interface
  interface_node = node['network']['interfaces'][interface]['addresses']
  interface_node.select { |address, data| data['family'] == 'inet' }[0][0]
end

include_recipe "postgres::build"

case node['platform']
  when "smartos"
    available_ram = `prtconf -m`.chomp.to_i
end

node.default['postgres']['config']['shared_buffers_mb'] = (available_ram * 0.25).to_i
node.default['postgres']['config']['effective_cache_size_mb'] = (available_ram * 0.7).to_i

config        = node['postgres']['config']
os_user       = node['postgres']['user']
os_group      = node['postgres']['group']
service_name  = node['postgres']['service']
data_dir      = node['postgres']['data_dir']
bin_dir       = node['postgres']['prefix_dir'].gsub(/%VERSION%/, node['postgres']['version']) + "/bin"

# create postgres user if not already there
user os_user do
  comment "PostgreSQL User"
  action :create
end

group os_group do
  action :create
end

directory config["stats_temp_directory"] do
  owner os_user
  group os_group
end

directory "/opt/local/share/smf/method" do
  recursive true
  action :create
end

directory File.dirname(data_dir) do
  recursive true
  owner os_user
end

execute "running initdb for data dir #{data_dir}" do
  command "#{bin_dir}/initdb -D #{data_dir} -E 'UTF8'"
  user os_user
  not_if { File.exists?(data_dir)}
end

template "/opt/local/share/smf/method/postgres.sh" do
  source "postgres-service.sh.erb"
  mode "0700"
  owner os_user
  group os_group
  #notifies :reload, "service[#{service_name}]"
  variables(
      "bin_dir"  => bin_dir,
      "data_dir" => node['postgres']['data_dir'],
      "log_file" => node['postgres']['log_file']
  )
end

template "#{data_dir}/pg_hba.conf" do
  source "pg_hba.conf.erb"
  owner os_user
  group os_group
  mode "0600"
  #notifies :reload, "service[#{service_name}]"
  variables('replica' => false, 'connections' => node['postgres']['connections'] )
end

private_interface = nil
if node['postgres']['listen_addresses'].empty?
  node['postgres']['listen_interfaces'].each do |interface|
    node.default['postgres']['listen_addresses'] << listen_addr_for(interface)
  end
end

if node['postgres']['listen_addresses'].empty?
  raise "Can't find any listen_addresses to bind to"
end

template "#{data_dir}/postgresql.conf" do
  source "postgresql.conf.erb"
  owner os_user
  group os_group
  mode "0600"
  #notifies :reload, "service[#{service_name}]"
  variables config.to_hash.merge('listen_addresses' => node['postgres']['listen_addresses'])
end

#if config['replica']
#  template "#{data_dir}/recovery.conf" do
#    source "#{os}.recovery.conf.erb"
#    owner os_user
#    group os_group
#    mode "0600"
#    notifies :reload, "service[#{service_name}]"
#    variables params
#  end
#end
#
#service service_name do
#  supports :status => true, :restart => true, :reload => true
#  action [ :enable, :start ]
#end
#
#ruby_block "wait for postgres to start up on first run" do
#  block do
#    sleep 15
#  end
#  not_if { node['postgresql']['enabled'] }
#end
#
#execute "set postgres password" do
#  command %Q(#{config['bin_dir']}/psql -U postgres -c "alter user postgres with password '#{config['password']}'")
#  only_if { config["password"] }
#end
#
#ruby_block "save postgresql enabled state for next chef run" do
#  block do
#    node.set['postgresql']['enabled'] = true
#  end
#end
#
