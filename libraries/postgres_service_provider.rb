require 'chef/mixin/shell_out'

class Chef
  class Provider
    # Provider for the postgres_service Chef provider
    #
    # postgres_service '9.4.5' do
    #   version '9.4.5'
    #   action :init
    # end
    #
    class PostgresService < Chef::Provider::LWRPBase
      include Chef::Mixin::ShellOut

      def load_current_resource
        @current_resource ||= new_resource.class.new(new_resource.name)
      end

      def action_enable
        if new_resource.already_running?
          Chef::Log.warn('Skipping enable because postgres is already running')
          return
        end
        new_resource.notifies_immediately(:enable, postgres_service)
        new_resource.updated_by_last_action(true)
      end

      def action_install
        new_resource.updated_by_last_action(false)

        run_context.include_recipe 'paths'
        run_context.include_recipe 'postgres::user'
        run_context.include_recipe 'resource-control'
        run_context.include_recipe 'smf'

        create_directories
        install_scripts
        configure_postgres
        configure_resource_controls
        configure_service
      end

      def action_reload
        new_resource.notifies_immediately(:reload, postgres_service)
        new_resource.updated_by_last_action(true)
      end

      def action_restart
        new_resource.notifies_immediately(:restart, postgres_service)
        new_resource.updated_by_last_action(true)
      end

      private

      def create_directories
        directory new_resource.stats_temp_directory do
          owner new_resource.os_user
          group new_resource.os_group
        end.run_action(:create)

        directory '/opt/local/share/smf/method' do
          recursive true
          action :create
        end.run_action(:create)

        directory ::File.dirname(new_resource.log_file) do
          recursive true
          owner new_resource.os_user
          group new_resource.os_group
        end.run_action(:create)
      end

      def install_scripts
        shell_script_resource = template new_resource.shell_script do
          source 'postgres-service.sh.erb'
          cookbook 'postgres'
          mode '0700'
          owner new_resource.os_user
          group new_resource.os_group
          variables(
              'bin_dir' => new_resource.bin_dir,
              'data_dir' => new_resource.data_dir,
              'log_file' => new_resource.log_file,
              'stats_dir' => new_resource.stats_temp_directory
          )
        end

        shell_script_resource.run_action(:create)

        new_resource.updated_by_last_action(true) if shell_script_resource.updated_by_last_action?

        template node['postgres']['config']['archive_script'] do
          source 'pg_archive_wal_logs.erb'
          cookbook 'postgres'
          owner new_resource.os_user
          group new_resource.os_group
          mode '0700'
          variables(
              'local_archive_script' => node['postgres']['config']['local_archive_script']
          )
        end.run_action(:create)
      end

      def configure_postgres
        pg_hba_resource = template "#{new_resource.data_dir}/pg_hba.conf" do
          source 'pg_hba.conf.erb'
          cookbook 'postgres'
          owner new_resource.os_user
          group new_resource.os_group
          mode '0600'
          variables('connections' => node['postgres']['connections'],
                    'replication' => node['postgres']['replication'])
        end

        pg_hba_resource.run_action(:create)

        pg_conf_resource = template "#{new_resource.data_dir}/postgresql.conf" do
          source 'postgresql.conf.erb'
          cookbook 'postgres'
          owner new_resource.os_user
          group new_resource.os_group
          mode '0600'
          variables new_resource.config.to_hash.merge(
                        'listen_addresses' => new_resource.listen_addresses,
                        'effective_cache_size_mb' => new_resource.effective_cache_size_mb,
                        'shared_buffers_mb' => new_resource.shared_buffers_mb
                    )
        end

        pg_conf_resource.run_action(:create)

        new_resource.updated_by_last_action(true) if pg_hba_resource.updated_by_last_action?
        new_resource.updated_by_last_action(true) if pg_conf_resource.updated_by_last_action?
      end

      def configure_resource_controls
        resource_control_project 'postgres' do
          comment 'PostgreSQL'
          users new_resource.os_user
        end
      end

      def configure_service
        smf new_resource.service_name do
          user new_resource.os_user
          group new_resource.os_group
          project 'postgres'
          start_command "#{new_resource.shell_script} start"
          stop_command "#{new_resource.shell_script} stop"
          refresh_command "#{new_resource.shell_script} refresh"
          start_timeout 60
          stop_timeout 60
          refresh_timeout 60
          environment 'PATH' => node['paths']['bin_path']
        end
      end

      def postgres_service
        begin
          run_context.resource_collection.find(service: new_resource.service_name)
        rescue Chef::Exceptions::ResourceNotFound
          service new_resource.service_name do
            supports reload: true, restart: true, status: true
          end
        end
      end
    end
  end
end
