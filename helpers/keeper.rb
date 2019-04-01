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

unless node[:proxy].kind_of?(Hash) then
  node[:proxy] = {}
end

proxy_regex = /^(socks|https?):\/\/(?:([0-9a-zA-Z-_\.]+):([0-9a-zA-Z-_\.]+)@)?([0-9a-zA-Z-_\.]+)(?::([0-9]+))?.*/

if ENV['HTTP_PROXY'] then
  node[:proxy][:proto] ||= ENV['HTTP_PROXY'].gsub(proxy_regex, '\1')
  node[:proxy][:user]  ||= ENV['HTTP_PROXY'].gsub(proxy_regex, '\2')
  node[:proxy][:pass]  ||= ENV['HTTP_PROXY'].gsub(proxy_regex, '\3')
  node[:proxy][:host]  ||= ENV['HTTP_PROXY'].gsub(proxy_regex, '\4')
  node[:proxy][:port]  ||= ENV['HTTP_PROXY'].gsub(proxy_regex, '\5').to_i
  node[:proxy][:uri]   ||= ENV['HTTP_PROXY']
elsif ENV['http_proxy'] then
  node[:proxy][:proto] ||= ENV['http_proxy'].gsub(proxy_regex, '\1')
  node[:proxy][:user]  ||= ENV['http_proxy'].gsub(proxy_regex, '\2')
  node[:proxy][:pass]  ||= ENV['http_proxy'].gsub(proxy_regex, '\3')
  node[:proxy][:host]  ||= ENV['http_proxy'].gsub(proxy_regex, '\4')
  node[:proxy][:port]  ||= ENV['http_proxy'].gsub(proxy_regex, '\5').to_i
  node[:proxy][:uri]   ||= ENV['http_proxy']
elsif ENV['HTTPS_PROXY'] then
  node[:proxy][:proto] ||= ENV['HTTPS_PROXY'].gsub(proxy_regex, '\1')
  node[:proxy][:user]  ||= ENV['HTTPS_PROXY'].gsub(proxy_regex, '\2')
  node[:proxy][:pass]  ||= ENV['HTTPS_PROXY'].gsub(proxy_regex, '\3')
  node[:proxy][:host]  ||= ENV['HTTPS_PROXY'].gsub(proxy_regex, '\4')
  node[:proxy][:port]  ||= ENV['HTTPS_PROXY'].gsub(proxy_regex, '\5').to_i
  node[:proxy][:uri]   ||= ENV['HTTPS_PROXY']
elsif ENV['https_proxy'] then
  node[:proxy][:proto] ||= ENV['https_proxy'].gsub(proxy_regex, '\1')
  node[:proxy][:user]  ||= ENV['https_proxy'].gsub(proxy_regex, '\2')
  node[:proxy][:pass]  ||= ENV['https_proxy'].gsub(proxy_regex, '\3')
  node[:proxy][:host]  ||= ENV['https_proxy'].gsub(proxy_regex, '\4')
  node[:proxy][:port]  ||= ENV['https_proxy'].gsub(proxy_regex, '\5').to_i
  node[:proxy][:uri]   ||= ENV['https_proxy']
end

if ENV['NO_PROXY'] then
  node[:proxy][:bypass] ||= ENV['NO_PROXY'].split(',')
elsif ENV['no_proxy'] then
  node[:proxy][:bypass] ||= ENV['no_proxy'].split(',')
end
if ENV['NO_PROXY'] or ENV['no_proxy'] then
  node[:proxy][:bypass].push('localhost')      unless node[:proxy][:bypass].include?('localhost')
  node[:proxy][:bypass].push('127.0.0.0/8')    unless node[:proxy][:bypass].include?('127.0.0.0/8')
  node[:proxy][:bypass].push('10.0.0.0/8')     unless node[:proxy][:bypass].include?('10.0.0.0/8')
  node[:proxy][:bypass].push('172.16.0.0/12')  unless node[:proxy][:bypass].include?('172.16.0.0/12')
  node[:proxy][:bypass].push('192.168.0.0/16') unless node[:proxy][:bypass].include?('192.168.0.0/16')
end
