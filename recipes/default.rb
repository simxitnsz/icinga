#
# Cookbook Name:: icinga
# Recipe:: default
# Author: Seth Thoenen
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

# Run apt-get update
bash 'run-apt-get-update' do
  code <<-EOH
  apt-get update
  EOH
  action :run
end


# Install software-propert9es-common so we can use add-apt-repository later
apt_package 'software-properties-common' do
  action :install
end

# Configure apt-get to find icinga packages
bash 'add icinga repository' do
  code <<-EOH
  add-apt-repository ppa:formorer/icinga
  apt-get update
  EOH
  action :run
  not_if { File.exist?('/etc/apt/sources.list.d/formorer-icinga-trusty.list') }
end

# Install icinga2 package
apt_package 'icinga2' do
  action :install
end

# Install MySQL Server
apt_package 'mysql-server' do
  action :install
end

# Install MySQL Client
apt_package 'mysql-client' do
  action :install
end

# Install icinga2 MySQL package
apt_package 'icinga2-ido-mysql' do
  action :install
  notifies :create, 'template[/tmp/icinga-sql.sql]', :immediately
end

# place .sql file on local machiene
template '/tmp/icinga-sql.sql' do
  action :nothing
  source 'icinga-sql.erb'
  owner 'root'
  mode '0755'
  notifies :run, 'bash[execute-icinga-sql]', :immediately
end

# Execute SQL command to create icinga database
bash 'execute-icinga-sql' do
  action :nothing
  code <<-EOH
  mysql -u root < /tmp/icinga-sql.sql
  EOH
  notifies :run, 'bash[create-icinga-database-schema]', :immediately
end

# Configure icinga
bash 'create-icinga-database-schema' do
  code <<-EOH
  mysql -u root icinga < /usr/share/icinga2-ido-mysql/schema/mysql.sql
  EOH
  action :nothing
  notifies :run, 'bash[enable-ido-mysql]', :immediately
end

# enable ido sql feature
bash 'enable-ido-mysql' do
  code <<-EOH
  icinga2 feature enable ido-mysql
  EOH
  action :nothing
  notifies :run, 'bash[restart-icinga2-service]'
end

# restart icinga service
bash 'restart-icinga2-service' do
  code <<-EOH
  service icinga2 restart
  EOH
  action :nothing
end

# install apache
apt_package 'apache2' do
  action :install
  notifies :run, 'bash[disable-page-speed-module]'
end

# Disable page speed module in apache
bash 'disable-page-speed-module' do
  code <<-EOH
  sudo sed -i "$ a\\ModPagespeedDisallow '*/icingaweb2/*'" /etc/apache2/apache2.conf
  EOH
  action :nothing
  notifies :run, 'bash[enable-firewall-rules]'
end

# enable http and https traffic
bash 'enable-firewall-rules' do
  code <<-EOH
  iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
  iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
  EOH
  action :nothing
  notifies :run, 'bash[enable-external-command-pipe]'
end

# Set up external command pipe
bash 'enable-external-command-pipe' do
  code <<-EOH
  icinga2 feature enable command
  service icinga2 restart
  usermod -a -G nagios www-data
  EOH
  action :nothing
end

# Install icingaweb2 package
apt_package 'icingaweb2' do
  action :install
end

# Add icingaweb2 user to system group
bash 'add-icingaweb2-to-system-group' do
  code <<-EOH
  addgroup --system icingaweb2
  usermod -a -G icingaweb2 www-data
  service apache2 restart
  EOH
  action :run
end

