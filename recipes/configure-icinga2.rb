#
# Cookbook Name:: icinga
# Recipe:: configure-icinga2
# Author: Seth Thoenen
#
# Copyright (c) 2016 Seth Thoenen, All Rights Reserved.

# Populate hosts variable with servers from data bag
hosts = data_bag_item('icinga', 'servers')['hosts']

# Place hosts.conf on local disk
template '/etc/icinga2/conf.d/hosts.conf' do
  source 'hosts-conf.erb'
  owner 'root'
  mode '0755'
  action :create
  variables({
    :hosts => hosts
  })
  notifies :run, 'bash[restart-icinga2-service]'
end

# Place services.conf on local disk
template '/etc/icinga2/conf.d/services.conf' do
  source 'services-conf.erb'
  owner 'root'
  mode '0755'
  action :create
  notifies :run, 'bash[restart-icinga2-service]'
end

# Populate users variable with users from data bag
users = data_bag_item('icinga', 'users')['users']

# Place users.conf on local disk
template '/etc/icinga2/conf.d/users.conf' do
  source 'users-conf.erb'
  owner 'root'
  mode '0755'
  action :create
  variables({
    :users => users
  })
  notifies :run, 'bash[restart-icinga2-service]'
end

# Restart icinga2 service. This is needed after .conf files are modified.
bash 'restart-icinga2-service' do
  code <<-EOH
  service icinga2 restart
  EOH
  action :nothing
end