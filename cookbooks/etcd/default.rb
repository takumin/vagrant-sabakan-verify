#
# Configuration
#

version = 'v3.3.12'
sha256sum = 'dc5d82df095dae0a2970e4d870b6929590689dd707ae3d33e7b86da0f7f211b6'

#
# Public Variables
#

unless node[:etcd].kind_of?(Hash) then
  node[:etcd] = Hashie::Mash.new({})
end
unless node[:etcd][:enabled].kind_of?(FalseClass) || node[:etcd][:enabled].kind_of?(TrueClass) then
  node[:etcd][:enabled] = false
end
unless node[:etcd][:prefix].kind_of?(String) then
  node[:etcd][:prefix] = '/usr/local'
end
unless node[:etcd][:owner].kind_of?(String) then
  node[:etcd][:owner] = 'etcd'
end
unless node[:etcd][:config].kind_of?(Hash) then
  node[:etcd][:config] = Hashie::Mash.new({})
end
unless node[:etcd][:config]['data-dir'].kind_of?(String) then
  node[:etcd][:config]['data-dir'] = '/var/lib/etcd'
end
unless node[:etcd][:environment].kind_of?(Hash) then
  node[:etcd][:environment] = Hashie::Mash.new({})
end

#
# Private Variables
#

options = []

node[:etcd][:config].each do |k, v|
  options << "--#{k}"
  options << "#{v}"
end

#
# Download Archive
#

http_request "/tmp/etcd-#{version}-linux-amd64.tar.gz" do
  url "https://github.com/etcd-io/etcd/releases/download/#{version}/etcd-#{version}-linux-amd64.tar.gz"
  not_if [
    "test -e #{node[:etcd][:prefix]}/bin/etcd",
    "test -e /tmp/etcd-#{version}-linux-amd64.tar.gz",
    "echo #{sha256sum} /tmp/etcd-#{version}-linux-amd64.tar.gz | sha256sum -c --ignore-missing --status",
  ].join(' || ')
  check_error true
end

#
# Extract Archive
#

execute "tar -xvf /tmp/etcd-#{version}-linux-amd64.tar.gz -C /tmp" do
  not_if [
    "test -e #{node[:etcd][:prefix]}/bin/etcd",
    "test -e /tmp/etcd-#{version}-linux-amd64",
  ].join(' || ')
end

#
# Install Archive
#

execute 'install etcd' do
  command "install -o root -g root -m 0755 /tmp/etcd-#{version}-linux-amd64/etcd #{node[:etcd][:prefix]}/bin/etcd"
  not_if "test -e #{node[:etcd][:prefix]}/bin/etcd"
end

execute 'install etcdctl' do
  command "install -o root -g root -m 0755 /tmp/etcd-#{version}-linux-amd64/etcdctl #{node[:etcd][:prefix]}/bin/etcdctl"
  not_if "test -e #{node[:etcd][:prefix]}/bin/etcdctl"
end

#
# Permission Binary
#

file "#{node[:etcd][:prefix]}/bin/etcd" do
  owner 'root'
  group 'root'
  mode '0755'
end

file "#{node[:etcd][:prefix]}/bin/etcdctl" do
  owner 'root'
  group 'root'
  mode '0755'
end

#
# Cleanup Archive
#

directory "/tmp/etcd-#{version}-linux-amd64" do
  action :delete
  only_if [
    "test -e #{node[:etcd][:prefix]}/bin/etcd",
    "test -e #{node[:etcd][:prefix]}/bin/etcdctl",
    "test -e /tmp/etcd-#{version}-linux-amd64",
  ].join(' && ')
end

file "/tmp/etcd-#{version}-linux-amd64.tar.gz" do
  action :delete
  only_if [
    "test -e #{node[:etcd][:prefix]}/bin/etcd",
    "test -e #{node[:etcd][:prefix]}/bin/etcdctl",
    "test -e /tmp/etcd-#{version}-linux-amd64.tar.gz",
  ].join(' && ')
end

#
# Owner/Group
#

user "#{node[:etcd][:owner]}" do
  system_user true
  shell '/usr/sbin/nologin'
  home '/nonexistent'
  create_home false
end

#
# Configuration Service
#

directory "#{node[:etcd][:config]['data-dir']}" do
  owner "#{node[:etcd][:owner]}"
  group "#{node[:etcd][:owner]}"
  mode '0755'
end

template '/etc/systemd/system/etcd.service' do
  owner 'root'
  group 'root'
  mode  '0644'
  variables(options: options)
  source 'templates/systemd.service.erb'
end

template '/etc/default/etcd' do
  owner 'root'
  group 'root'
  mode  '0644'
  source 'templates/environment.erb'
end

if node[:etcd][:enabled] then
  action = [:enable, :start]
else
  action = [:disable, :stop]
end

service 'etcd.service' do
  action action
end

#
# Event Handler
#

execute 'systemctl daemon-reload' do
  action :nothing
  subscribes :run, 'template[/etc/systemd/system/etcd.service]'
end

if node[:etcd][:enabled] then
  execute 'systemctl restart etcd.service' do
    action :nothing
    subscribes :run, 'execute[install etcd]'
    subscribes :run, 'template[/etc/systemd/system/etcd.service]'
    subscribes :run, 'template[/etc/default/etcd]'
  end
end
