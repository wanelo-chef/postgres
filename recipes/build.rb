
# create temporary src directory /root/src, /opt/local/src
# Chef::Config['file_cache_path']


version     = node['postgres']['version']
prefix_dir  = node['postgres']['prefix_dir'].gsub(/%VERSION%/, version)
bin_dir     = prefix_dir + "/bin"

tarfile = "#{Chef::Config['file_cache_path']}/postgresql-#{version}.tar.gz"
src_dir = "#{Chef::Config['file_cache_path']}/postgresql-#{version}"

remote_file tarfile do
  source node['postgres']['remote_tar'].gsub('%VERSION%', version)
  mode 00644
  not_if { File.exist?(tarfile) }
end

bash "install postgres from source" do
  cwd Chef::Config['file_cache_path']
  code <<-EOH
    rm -rf #{src_dir}
    tar zxvf #{tarfile}
    cd #{src_dir}
    MAKEFLAGS="-j6" ./configure --prefix=#{prefix_dir} --with-template=solaris \
        --enable-nls --without-perl --without-python --without-readline \
        --without-tcl --without-zlib --enable-dtrace --with-openssl \
        --build=x86_64-sun-solaris2.11 --host=x86_64-sun-solaris2.11
    make
    make install
  EOH
  not_if "ls -1 #{bin_dir}/postgres"
end

