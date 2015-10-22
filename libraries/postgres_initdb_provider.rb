require 'chef/mixin/shell_out'

class Chef
  class Provider
    # Provider for the postgres_initdb Chef provider
    #
    # postgres_initdb 'initialize db for postgres 9.4' do
    #   version '9.4.5'
    #   action :init
    # end
    #
    class PostgresInitdb < Chef::Provider::LWRPBase
      include Chef::Mixin::ShellOut

      def load_current_resource
        @current_resource ||= new_resource.class.new(new_resource.name)
      end

      def action_init
        run_context.include_recipe 'postgres::user'

        directory ::File.dirname(new_resource.data_dir) do
          recursive true
          owner new_resource.user
        end

        execute "running initdb for data dir #{new_resource.data_dir}" do
          command "#{new_resource.bin_dir}/initdb -D #{new_resource.data_dir} -E '#{new_resource.encoding}' --locale='#{new_resource.locale}'"
          user new_resource.user
          not_if { ::File.exists?(new_resource.data_dir)}
        end
      end
    end
  end
end
