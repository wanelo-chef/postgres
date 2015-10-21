class Chef
  class Resource
    # Resource for the postgres_compile Chef provider
    #
    # postgres_compile 'install postgres 9.4' do
    #   version '9.4.5'
    #   action :compile
    # end
    #
    class PostgresCompile < Chef::Resource
      def initialize(name, run_context = nil)
        super
        @resource_name = :postgres_compile
        @provider = Chef::Provider::PostgresCompile
        @action = :compile
        @allowed_actions = [:compile, :nothing]
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

      def contrib_dir
        "#{Chef::Config['file_cache_path']}/postgresql-#{version}/contrib"
      end

      def prefix_dir
        node['postgres']['prefix_dir'].gsub(/%VERSION%/, version)
      end

      def source_dir
        "#{Chef::Config['file_cache_path']}/postgresql-#{version}"
      end

      def tarfile
        "#{Chef::Config['file_cache_path']}/postgresql-#{version}.tar.gz"
      end

      def tarfile_source
        node['postgres']['remote_tar'].gsub('%VERSION%', version)
      end

    end
  end
end
