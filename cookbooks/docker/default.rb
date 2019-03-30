compose_version = '1.24.0'
compose_sha256sum = 'bee6460f96339d5d978bb63d17943f773e1a140242dfa6c941d5e020a302c91b'

unless node[:docker].kind_of?(Hash) then
  node[:docker] = {}
end
unless node[:docker][:config].kind_of?(Hash) then
  node[:docker][:config] = {}
end
unless node[:docker][:compose].kind_of?(Hash) then
  node[:docker][:compose] = {}
end
unless node[:docker][:compose][:prefix].kind_of?(String) then
  node[:docker][:compose][:prefix] = '/usr/local'
end

#
# Package
#

apt_keyring 'Docker Release (CE deb) <docker@docker.com>' do
  finger '9DC858229FC7DD38854AE2D88D81803C0EBFCD88'
end

apt_repository 'Docker Repository' do
  path '/etc/apt/sources.list.d/docker.list'
  entry [
    {
      :default_uri => 'https://download.docker.com/linux/ubuntu',
      :mirror_uri  => "#{ENV['DOCKER_MIRROR']}",
      :options     => 'arch=amd64',
      :suite       => "#{node['platform_codename']}",
      :components  => [
        'stable',
      ],
    },
  ]
  notifies :run, "execute[apt-get update]", :immediately
end

execute 'apt-get update' do
  action :nothing
end

package 'docker-ce'
package 'cockpit-docker' do
  only_if 'dpkg -l | grep -qs cockpit'
end

#
# Grub
#

cmdline = {
  'cgroup_enable' => 'memory',
  'swapaccount'   => '1',
}

cmdline.each do |key, val|
  execute "perl -pi -e 's@^(GRUB_CMDLINE_LINUX_DEFAULT=(?!.*#{key})\"[^\"]+)(\".*)@\\1 #{key}=#{val}\\2@' /etc/default/grub" do
    not_if "test ! -e /etc/default/grub || grep -qs '^GRUB_CMDLINE_LINUX_DEFAULT=.*#{key}=#{val}.*' /etc/default/grub"
    notifies :run, "execute[update-grub]"
  end
end

execute 'update-grub' do
  action :nothing
end

#
# Service
#

directory '/etc/systemd/system/docker.service.d' do
  owner 'root'
  group 'root'
  mode  '0755'
end

remote_file '/etc/systemd/system/docker.service.d/environment.conf' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :run, "execute[systemctl daemon-reload]"
  notifies :restart, "service[docker.service]"
end

template '/etc/default/docker' do
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :restart, "service[docker.service]"
end

if node[:docker][:config] != {} then
  file '/etc/docker/daemon.json' do
    owner 'root'
    group 'root'
    mode '0600'
    content JSON.pretty_generate(node[:docker][:config])
    notifies :restart, 'service[serf.service]'
  end
end

execute 'systemctl daemon-reload' do
  action :nothing
end

service 'docker.service' do
  action [:enable, :start]
end

#
# Admin
#

execute "usermod -aG docker #{node[:current][:user]}" do
  not_if "grep -qs '^docker.*#{node[:current][:user]}' /etc/group"
end

check_compose_version = run_command("#{node[:docker][:compose][:prefix]}/bin/docker-compose --version", error: false)

if check_compose_version.exit_status == 0 then
  installed_compose_version = check_compose_version.stdout.lines[0].gsub(/.*version ([0-9]+\.[0-9]+\.[0-9]+).*$/, '\1').chomp

  if installed_compose_version != compose_version then
    execute "rm -f #{node[:docker][:compose][:prefix]}/bin/docker-compose" do
      only_if "test -e #{node[:docker][:compose][:prefix]}/bin/docker-compose"
    end
  end
end

#
# Compose
#

kern = run_command(['uname', '-s']).stdout.gsub(/\r\n|\r|\n|\s|\t/, '')
arch = run_command(['uname', '-m']).stdout.gsub(/\r\n|\r|\n|\s|\t/, '')

http_request "#{node[:docker][:compose][:prefix]}/bin/docker-compose" do
  url "https://github.com/docker/compose/releases/download/#{compose_version}/docker-compose-#{kern}-#{arch}"
  not_if "test -e #{node[:docker][:compose][:prefix]}/bin/docker-compose || echo #{compose_sha256sum} #{node[:docker][:compose][:prefix]}/bin/docker-compose | sha256sum -c --ignore-missing --status"
  check_error true
end

file "#{node[:docker][:compose][:prefix]}/bin/docker-compose" do
  owner 'root'
  group 'root'
  mode '0755'
end
