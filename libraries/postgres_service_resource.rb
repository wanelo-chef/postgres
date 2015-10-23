class Chef
  class Resource
    # Resource for the postgres_service Chef provider
    #
    # postgres_service '9.4.5' do
    #   version '9.4.5'
    #   action :install
    #   notifies :reload, 'postgres_service[9.4.5]'
    # end
    #
    class PostgresService < Chef::Resource
      include Chef::Mixin::ShellOut

      def initialize(name, run_context = nil)
        super
        @resource_name = :postgres_service
        @provider = Chef::Provider::PostgresService
        @action = :install
        @allowed_actions = [:enable, :install, :reload, :restart, :nothing]
      end

      def name(arg = nil)
        set_or_return(:name, arg, kind_of: String, required: true)
      end

      def version(arg = nil)
        set_or_return(:version, arg, kind_of: String, required: true)
      end

      def bin_dir
        node['postgres']['prefix_dir'].gsub(/%VERSION%/, version) + '/bin'
      end

      def config
        node['postgres']['config']
      end

      def data_dir
        node['postgres']['data_dir'].gsub(/%VERSION_ABBR%/, version_abbr)
      end

      def effective_cache_size_mb
        (available_ram * 0.95).to_i - shared_buffers_mb
      end

      def listen_addresses
        [].tap do |addrs|
          addrs << '127.0.0.1'
          addrs << node['privateaddress'] if node['postgres']['bind_privateaddress'] && node['privateaddress']
          addrs << node['ipaddress'] if node['postgres']['bind_publicaddress']
        end
      end

      def log_file
        node['postgres']['log_file'].gsub(/%VERSION%/, version)
      end

      def os_user
        node['postgres']['user']
      end

      def os_group
        node['postgres']['group']
      end

      def already_running?
        !(shell_out("ps -ef | grep '[p]ostgres -D'").error? ||
            shell_out('svcs -a | grep postgres | grep online').error?)
      end

      # postgres945
      def service_name
        "#{node['postgres']['service']}#{version_num}"
      end

      def shared_buffers_mb
        [12000, (available_ram * 0.25).to_i].min
      end

      def shell_script
        "/opt/local/share/smf/method/postgres-#{version}.sh"
      end

      def stats_temp_directory
        config['stats_temp_directory']
      end

      private

      def available_ram
        case node['platform']
          when 'smartos'
            shell_out!('prtconf -m').stdout.chomp.to_i
          when 'linux'
            shell_out!("free | grep Mem | awk '{print $2}'").stdout.chomp.to_i / 1024
        end
      end

      # 9.4.5 -> 94
      def version_abbr
        version.split('.').slice(0..1).join
      end

      # 9.4.5 -> 945
      def version_num
        version.split('.').join
      end
    end
  end
end
