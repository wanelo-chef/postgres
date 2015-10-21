require 'chef/mixin/shell_out'

class Chef
  class Provider
    # Provider for the postgres_compile Chef provider
    #
    # postgres_compile 'install postgres 9.4' do
    #   version '9.4.5'
    #   action :compile
    # end
    #
    class PostgresCompile < Chef::Provider::LWRPBase
      include Chef::Mixin::ShellOut

      def load_current_resource
        @current_resource ||= new_resource.class.new(new_resource.name)
      end

      def action_compile
        install_dependencies
        download_tarball
        compile_source
        compile_contrib
      end

      private

      def install_dependencies
        run_context.include_recipe 'build-essential'
        %w[bison flex readline zlib].each do |package_name|
          package package_name do
            action :install
          end
        end
      end

      def download_tarball
        remote_file new_resource.tarfile do
          source new_resource.tarfile_source
          mode 00644
          not_if { ::File.exist?(new_resource.tarfile) }
        end
      end

      def compile_source
        bash "install postgres #{new_resource.version} from source" do
          cwd Chef::Config['file_cache_path']
          code <<-EOH
            rm -rf #{new_resource.source_dir}
            tar zxvf #{new_resource.tarfile}
            cd #{new_resource.source_dir}
            ./configure --prefix=#{new_resource.prefix_dir} --with-template=solaris \
                --enable-nls --without-perl --without-python  \
                --without-tcl --enable-dtrace --with-openssl  \
                --build=x86_64-sun-solaris2.11 --host=x86_64-sun-solaris2.11 \
                --with-libraries=/opt/local/lib --with-includes=/opt/local/include
            make -j 12
            make install
          EOH

          environment 'CFLAGS' => '-lintl',
                      'FFLAGS' => '-m64',
                      'LDFLAGS' => '-Wl,-R/opt/local/lib -L/opt/local/lib -lintl'

          not_if "ls -1 #{new_resource.bin_dir}/postgres"
        end
      end

      def compile_contrib
        execute "install postgres #{new_resource.version} contrib extensions" do
          cwd new_resource.contrib_dir
          command 'make && make install'
          not_if { ::File.exists?("#{new_resource.bin_dir}/pg_upgrade") }
        end
      end
    end
  end
end
