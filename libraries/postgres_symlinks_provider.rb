class Chef
  class Provider
    # Provider for the postgres_symlinks Chef provider
    #
    # For an installed version of postgres, symlink necessary
    # binaries into /opt/local/bin and libraries into /opt/local/lib
    #
    # postgres_symlinks '9.4.5' do
    #   action :link
    # end
    #
    class PostgresSymlinks < Chef::Provider::LWRPBase
      def load_current_resource
        @current_resource ||= new_resource.class.new(new_resource.name)
      end

      def action_link
        link_binaries
        link_libraries
      end

      private

      def link_binaries
        %w(
          clusterdb   ecpg            pg_dumpall      postgres
          createdb    initdb          pg_isready      postmaster
          createlang  pg_basebackup   pg_receivexlog  psql
          createuser  pg_config       pg_resetxlog    reindexdb
          dropdb      pg_controldata  pg_restore      vacuumdb
          droplang    pg_ctl          pg_upgrade
          dropuser    pg_dump         pgbench
        ).each do |cmd|
          link "/opt/local/bin/#{cmd}" do
            to "#{new_resource.prefix_dir}/bin/#{cmd}"
          end
        end
      end

      def link_libraries
        # This assumes that the major version of libpq that ships with
        # postgres `version` is 5. To be fixed when that is no longer
        # the case.
        %w(
           libpq.so libpq.so.5
        ).each do |lib|
          link "/opt/local/lib/#{lib}" do
            to "#{new_resource.prefix_dir}/lib/#{lib}"
            not_if "test -e /opt/local/lib/#{lib}"
          end
        end
      end
    end
  end
end
