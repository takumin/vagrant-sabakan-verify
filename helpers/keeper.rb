node[:current]         ||= {}
node[:current][:user]  ||= ENV['SUDO_USER'] || ENV['USER']
node[:current][:home]  ||= node[:user][node[:current][:user]][:home]
node[:current][:shell] ||= node[:user][node[:current][:user]][:shell]
node[:current][:uid]   ||= node[:user][node[:current][:user]][:uid]
node[:current][:gid]   ||= node[:user][node[:current][:user]][:gid]

case node['platform']
when 'debian'
  node['platform_family'] ||= 'debian'
when 'ubuntu'
  case node['platform_version']
  when '12.04'
    node['platform_codename'] ||= 'precise'
  when '14.04'
    node['platform_codename'] ||= 'trusty'
  when '16.04'
    node['platform_codename'] ||= 'xenial'
  when '18.04'
    node['platform_codename'] ||= 'bionic'
  end
  node['platform_family'] ||= 'debian'
end
