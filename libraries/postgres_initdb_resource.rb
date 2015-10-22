class Chef
  class Resource
    # Resource for the postgres_initdb Chef provider
    #
    # This resource initializes a Postgres data directory
    # for a specified Postgres version. For instance, version 9.4.5
    # will initialize a data directory at /var/pgsql/data94.
    #
    # postgres_initdb 'initialize postgres 9.4 data directory' do
    #   version '9.4.5'
    #   action :init
    # end
    #
    class PostgresInitdb < Chef::Resource
      def initialize(name, run_context = nil)
        super
        @resource_name = :postgres_initdb
        @provider = Chef::Provider::PostgresInitdb
        @action = :init
        @allowed_actions = [:init, :nothing]
      end

      def name(arg = nil)
        set_or_return(:name, arg, kind_of: String, required: true)
      end

      def version(arg = nil)
        set_or_return(:version, arg, kind_of: String, required: true)
      end

      def bin_dir
        "#{prefix_dir}/bin"
      end

      def data_dir
        node['postgres']['data_dir'].gsub(/%VERSION_ABBR%/, version_abbreviation)
      end

      def group
        node['postgres']['group']
      end

      def prefix_dir
        node['postgres']['prefix_dir'].gsub(/%VERSION%/, version)
      end

      def user
        node['postgres']['user']
      end

      def encoding
        node['postgres']['config']['encoding']
      end

      def locale
        node['postgres']['config']['locale']
      end

      def version_abbreviation
        version.split('.').slice(0..1).join
      end
    end
  end
end
