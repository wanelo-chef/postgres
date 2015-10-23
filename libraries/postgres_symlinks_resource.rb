class Chef
  class Resource
    # Resource for the postgres_symlinks Chef provider
    #
    # For an installed version of postgres, symlink necessary
    # binaries into /opt/local/bin and libraries into /opt/local/lib
    #
    # postgres_symlinks '9.4.5' do
    #   action :link
    # end
    #
    class PostgresSymlinks < Chef::Resource
      def initialize(name, run_context = nil)
        super
        @resource_name = :postgres_symlinks
        @provider = Chef::Provider::PostgresSymlinks
        @action = :link
        @allowed_actions = [:link, :nothing]
      end

      def name(arg = nil)
        set_or_return(:name, arg, kind_of: String, required: true)
      end

      def prefix_dir
        node['postgres']['prefix_dir'].gsub(/%VERSION%/, version)
      end

      def version
        name
      end
    end
  end
end
