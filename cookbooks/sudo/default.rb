#
# Node Variables
#

unless node[:sudo].kind_of?(Hash) then
  node[:sudo] = {}
end
unless node[:sudo][:sudoers].kind_of?(Hash) then
  node[:sudo][:sudoers] = {}
end
unless node[:sudo][:sudoers][:keep_proxy].kind_of?(Array) then
  node[:sudo][:sudoers][:keep_proxy] = <<-__EOF__
# vim: set ft=sudoers :

# Default Proxy
Defaults  env_keep+="no_proxy"
Defaults  env_keep+="NO_PROXY"
Defaults  env_keep+="ftp_proxy"
Defaults  env_keep+="FTP_PROXY"
Defaults  env_keep+="http_proxy"
Defaults  env_keep+="HTTP_PROXY"
Defaults  env_keep+="https_proxy"
Defaults  env_keep+="HTTPS_PROXY"

# Auth Proxy
Defaults  env_keep+="PROXY_PROT"
Defaults  env_keep+="PROXY_HOST"
Defaults  env_keep+="PROXY_PORT"
Defaults  env_keep+="PROXY_USER"
Defaults  env_keep+="PROXY_PASS"

# Apt Proxy
Defaults  env_keep+="APT_PROXY_PROT"
Defaults  env_keep+="APT_PROXY_HOST"
Defaults  env_keep+="APT_PROXY_PORT"
Defaults  env_keep+="APT_PROXY_USER"
Defaults  env_keep+="APT_PROXY_PASS"
  __EOF__
end
unless node[:sudo][:sudoers][:no_passwd].kind_of?(Array) then
  node[:sudo][:sudoers][:no_passwd] = <<-__EOF__
# vim: set ft=sudoers :

# No password for sudo group
%sudo ALL=(ALL:ALL) NOPASSWD: ALL
  __EOF__
end

#
# Install Package
#

package 'sudo'

#
# Cleanup Directory
#

Dir.glob('/etc/sudoers.d/*').sort.each do |path|
  key = File.basename(path)

  if node[:sudo][:sudoers].keys.include?(key) or key == 'README' then
    next
  end

  file path do
    action :delete
  end
end

#
# Configuration
#

node[:sudo][:sudoers].each do |key, val|
  file "/etc/sudoers.d/#{key}" do
    owner 'root'
    group 'root'
    mode  '0644'
    content(val)
  end
end
