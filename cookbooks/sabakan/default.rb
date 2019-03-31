#
# Public Variables
#

unless node[:sabakan].kind_of?(Hash) then
  node[:sabakan] = {}
end
unless node[:sabakan][:enabled].kind_of?(FalseClass) || node[:sabakan][:enabled].kind_of?(TrueClass) then
  node[:sabakan][:enabled] = false
end
unless node[:sabakan][:prefix].kind_of?(String) then
  node[:sabakan][:prefix] = '/usr/local'
end
unless node[:sabakan][:owner].kind_of?(String) then
  node[:sabakan][:owner] = 'sabakan'
end
unless node[:sabakan][:repository].kind_of?(String) then
  node[:sabakan][:repository] = 'github.com/cybozu-go/sabakan'
end
unless node[:sabakan][:directory].kind_of?(Hash) then
  node[:sabakan][:directory] = {}
end
unless node[:sabakan][:directory][:data].kind_of?(Hash) then
  node[:sabakan][:directory][:data] = {}
end
unless node[:sabakan][:directory][:data][:path].kind_of?(String) then
  node[:sabakan][:directory][:data][:path] = '/var/lib/sabakan'
end
unless node[:sabakan][:file].kind_of?(Hash) then
  node[:sabakan][:file] = {}
end
unless node[:sabakan][:file][:config].kind_of?(Hash) then
  node[:sabakan][:file][:config] = {}
end
unless node[:sabakan][:file][:config][:path].kind_of?(String) then
  node[:sabakan][:file][:config][:path] = '/etc/sabakan.yml'
end
unless node[:sabakan][:config].kind_of?(Hash) then
  node[:sabakan][:config] = {}
end
unless node[:sabakan][:config]['etcd'].kind_of?(Hash) then
  node[:sabakan][:config]['etcd'] = {}
end
unless node[:sabakan][:config]['etcd']['endpoints'].kind_of?(Array) then
  node[:sabakan][:config]['etcd']['endpoints'] = ['http://localhost:2379']
end
unless node[:sabakan][:config]['advertise-url'].kind_of?(String) then
  node[:sabakan][:config]['advertise-url'] = 'http://localhost:10080'
end
unless node[:sabakan][:config]['allow-ips'].kind_of?(Array) then
  node[:sabakan][:config]['allow-ips'] = ['127.0.0.1', '::1']
end
unless node[:sabakan][:config]['data-dir'].kind_of?(String) then
  node[:sabakan][:config]['data-dir'] = "#{node[:sabakan][:directory][:data][:path]}"
end
unless node[:sabakan][:config]['dhcp-bind'].kind_of?(String) then
  node[:sabakan][:config]['dhcp-bind'] = '0.0.0.0:10067'
end
unless node[:sabakan][:config]['enable-playground'].kind_of?(FalseClass) || node[:sabakan][:config]['enable-playground'].kind_of?(TrueClass) then
  node[:sabakan][:config]['enable-playground'] = false
end
unless node[:sabakan][:config]['http'].kind_of?(String) then
  node[:sabakan][:config]['http'] = '0.0.0.0:10080'
end
unless node[:sabakan][:config]['ipxe-efi-path'].kind_of?(String) then
  node[:sabakan][:config]['ipxe-efi-path'] = '/usr/lib/ipxe/ipxe.efi'
end
unless node[:sabakan][:environment].kind_of?(Hash) then
  node[:sabakan][:environment] = {}
end

execute 'go get sabakan repository' do
  command "env GOPATH=/tmp/sabakan /usr/local/go/bin/go get -u #{node[:sabakan][:repository]}/..."
  user "#{node['current']['user']}"
  not_if [
    'test -d /tmp/sabakan',
    "test -e #{node[:sabakan][:prefix]}/bin/sabakan",
    "test -e #{node[:sabakan][:prefix]}/bin/sabactl",
    "test -e #{node[:sabakan][:prefix]}/bin/sabakan-cryptsetup",
  ].join(' || ')
end

#
# Install Binary
#

execute 'install sabakan' do
  command "install -o root -g root -m 0755 /tmp/sabakan/bin/sabakan #{node[:sabakan][:prefix]}/bin/sabakan"
  not_if "test -e #{node[:sabakan][:prefix]}/bin/sabakan"
end

execute 'install sabactl' do
  command "install -o root -g root -m 0755 /tmp/sabakan/bin/sabactl #{node[:sabakan][:prefix]}/bin/sabactl"
  not_if "test -e #{node[:sabakan][:prefix]}/bin/sabactl"
end

execute 'install sabakan-cryptsetup' do
  command "install -o root -g root -m 0755 /tmp/sabakan/bin/sabakan-cryptsetup #{node[:sabakan][:prefix]}/bin/sabakan-cryptsetup"
  not_if "test -e #{node[:sabakan][:prefix]}/bin/sabakan-cryptsetup"
end

#
# Cleanup Directory
#

directory '/tmp/sabakan' do
  action :delete
  only_if [
    "test -e #{node[:sabakan][:prefix]}/bin/sabakan",
    "test -e #{node[:sabakan][:prefix]}/bin/sabactl",
    "test -e #{node[:sabakan][:prefix]}/bin/sabakan-cryptsetup",
  ].join(' && ')
end

#
# Permission Binary
#

file "#{node[:sabakan][:prefix]}/bin/sabakan" do
  owner 'root'
  group 'root'
  mode '0755'
end

file "#{node[:sabakan][:prefix]}/bin/sabactl" do
  owner 'root'
  group 'root'
  mode '0755'
end

file "#{node[:sabakan][:prefix]}/bin/sabakan-cryptsetup" do
  owner 'root'
  group 'root'
  mode '0755'
end

#
# Owner/Group
#

user "#{node[:sabakan][:owner]}" do
  system_user true
  shell '/usr/sbin/nologin'
  home '/nonexistent'
  create_home false
end

#
# Configuration Service
#

directory "#{node[:sabakan][:directory][:data][:path]}" do
  owner "#{node[:sabakan][:owner]}"
  group "#{node[:sabakan][:owner]}"
  mode '0755'
end

template "#{node[:sabakan][:file][:config][:path]}" do
  owner 'root'
  group 'root'
  mode  '0644'
  source 'templates/sabakan.yml.erb'
end

template '/etc/systemd/system/sabakan.service' do
  owner 'root'
  group 'root'
  mode  '0644'
  source 'templates/systemd.service.erb'
end

template '/etc/default/sabakan' do
  owner 'root'
  group 'root'
  mode  '0644'
  source 'templates/environment.erb'
end

if node[:sabakan][:enabled] then
  action = [:enable, :start]
else
  action = [:disable, :stop]
end

service 'sabakan.service' do
  action action
end

#
# Event Handler
#

execute 'systemctl daemon-reload' do
  action :nothing
  subscribes :run, 'template[/etc/systemd/system/sabakan.service]'
end

if node[:sabakan][:enabled] then
  execute 'systemctl restart sabakan.service' do
    action :nothing
    subscribes :run, 'execute[install sabakan]'
    subscribes :run, 'template[/etc/systemd/system/sabakan.service]'
    subscribes :run, 'template[/etc/default/sabakan]'
  end
end
