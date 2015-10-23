postgres_symlinks node['postgres']['version'] do
  action :link
end
