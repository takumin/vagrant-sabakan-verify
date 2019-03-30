# vim: set ft=ruby :

# Mirror Apt Repository
ENV['UBUNTU_PROXY']  ||= 'http://10.10.10.1:3142'
ENV['UBUNTU_MIRROR'] ||= 'http:///ubuntu'
ENV['DOCKER_MIRROR'] ||= 'http:///docker'

# EDK2 OVMF Github Release Tag
OVMF_RELEASE_TAG ||= '20190311'

# iPXE Github Release Tag
IPXE_RELEASE_TAG ||= 'v20190327'

# MItamae Github Release Tag
MITAMAE_RELEASE_TAG ||= 'v1.7.4'

# MItamae CookBooks
MITAMAE_COOKBOOKS = [
  'cookbooks/apt/default.rb',
  'cookbooks/require/default.rb',
  'cookbooks/docker/default.rb',
  'cookbooks/etcd/default.rb',
  'cookbooks/go/default.rb',
]

# MItamae Variables
require 'yaml'
YAML.dump({
  'etcd' => {
    'enabled' => true,
  },
}, File.open(File.join(File.expand_path(__dir__), 'vendor', 'mitamae.yaml'), 'w'))

# Download Require Binary
require 'open-uri'
[
  {
    :name => 'ovmf',
    :urls => [
      "https://github.com/takumin/travis-edk2/releases/download/#{OVMF_RELEASE_TAG}/OVNF_X64_CODE.fd",
      "https://github.com/takumin/travis-edk2/releases/download/#{OVMF_RELEASE_TAG}/OVNF_X64_VARS.fd",
    ],
  },
  {
    :name => 'ipxe',
    :urls => [
      "https://github.com/takumin/travis-ipxe/releases/download/#{IPXE_RELEASE_TAG}/undionly.kpxe",
      "https://github.com/takumin/travis-ipxe/releases/download/#{IPXE_RELEASE_TAG}/snponly-x86.efi",
      "https://github.com/takumin/travis-ipxe/releases/download/#{IPXE_RELEASE_TAG}/snponly-x64.efi",
    ],
  },
  {
    :name => 'mitamae',
    :urls => [
      "https://github.com/itamae-kitchen/mitamae/releases/download/#{MITAMAE_RELEASE_TAG}/mitamae-x86_64-linux",
    ],
  },
].each {|item|
  base_dir = File.join(File.expand_path(__dir__), 'vendor', item[:name])
  unless File.exist?(base_dir)
    Dir.mkdir(base_dir, 0755)
  end
  item[:urls].each {|url|
    path = File.join(base_dir, File.basename(url))
    unless File.exist?(path)
      p "Download: #{url}"
      open(url) do |file|
        open(path, 'w+b') do |out|
          out.write(file.read)
        end
      end
    end
  }
}

# Require Minimum Vagrant Version
Vagrant.require_version '>= 2.2.4'

# Vagrant Configuration
Vagrant.configure('2') do |config|
  # Require Plugins
  config.vagrant.plugins = ['vagrant-libvirt']

  # Disabled Default Sync
  config.vm.synced_folder '.', '/vagrant', disabled: true

  # Private Network
  config.vm.network :private_network,
    :ip => '10.10.10.2',
    :auto_config => false,
    :libvirt__network_name => 'vagrant-baremetal',
    :libvirt__dhcp_enabled => false,
    :libvirt__forward_mode => 'none',
    :libvirt__guest_ipv6 => 'no'
  config.vm.network :private_network,
    :ip => '10.10.10.3',
    :auto_config => false,
    :libvirt__network_name => 'vagrant-baremetal',
    :libvirt__dhcp_enabled => false,
    :libvirt__forward_mode => 'none',
    :libvirt__guest_ipv6 => 'no'

  # Libvirt Provider Configuration
  config.vm.provider :libvirt do |libvirt|
    # UEFI Firmware
    # libvirt.loader = File.join(File.expand_path(__dir__), 'vendor', 'ovmf', 'OVNF_X64_CODE.fd')
    # libvirt.nvram = File.join(File.expand_path(__dir__), 'vendor', 'ovmf', 'OVNF_X64_VARS.fd')
    # Monitor
    libvirt.graphics_type = 'spice'
    libvirt.graphics_ip = '127.0.0.1'
    libvirt.video_type = 'qxl'
    # Network
    libvirt.mgmt_attach = false
    libvirt.management_network_mode = 'nat'
    libvirt.management_network_guest_ipv6 = 'no'
  end

  if Vagrant.has_plugin?('vagrant-proxyconf')
    config.proxy.no_proxy = "#{ENV['no_proxy'] || ENV['NO_PROXY']}" if ENV['no_proxy'] || ENV['NO_PROXY']
    config.proxy.ftp      = "#{ENV['ftp_proxy'] || ENV['FTP_PROXY']}" if ENV['ftp_proxy'] || ENV['FTP_PROXY']
    config.proxy.http     = "#{ENV['http_proxy'] || ENV['HTTP_PROXY']}" if ENV['http_proxy'] || ENV['HTTP_PROXY']
    config.proxy.https    = "#{ENV['https_proxy'] || ENV['HTTPS_PROXY']}" if ENV['https_proxy'] || ENV['HTTPS_PROXY']
  end

  # Bootstrap Server
  config.vm.define :bootstrap do |domain|
    # Ubuntu 18.04 Box
    domain.vm.box = 'ubuntu1804'

    # Synced Directory
    domain.vm.synced_folder '.', '/vagrant',
      type: 'nfs',
      nfs_version: 4,
      nfs_udp: false,
      nfs_export: false

    # Guest Network Interfaces
    domain.vm.provision 'shell' do |shell|
      shell.name   = 'Guest Network Interfaces'
      shell.inline = <<~BASH
        {
          echo 'network:'
          echo '  version: 2'
          echo '  renderer: networkd'
          echo '  ethernets:'
          echo '    eth0:'
          echo '      dhcp4: true'
          echo '      optional: true'
          echo '    eth1:'
          echo '      optional: true'
          echo '    eth2:'
          echo '      optional: true'
          echo '    eth3:'
          echo '      optional: true'
          echo '    eth4:'
          echo '      optional: true'
          echo '  bonds:'
          echo '    bond0:'
          echo '      addresses:'
          echo '        - 10.10.10.2/24'
          echo '      interfaces:'
          echo '        - eth1'
          echo '        - eth2'
          echo '      parameters:'
          echo '        mode: balance-alb'
        } > "/etc/netplan/99-vagrant-network.yaml"

        netplan apply
      BASH
    end

    # MItamae Provision
    domain.vm.provision 'shell' do |shell|
      shell.name   = 'Provision mitamae'
      shell.env = {
        'no_proxy' => ENV['no_proxy'] || ENV['NO_PROXY'],
        'NO_PROXY' => ENV['no_proxy'] || ENV['NO_PROXY'],
        'ftp_proxy' => ENV['ftp_proxy'] || ENV['FTP_PROXY'],
        'FTP_PROXY' => ENV['ftp_proxy'] || ENV['FTP_PROXY'],
        'http_proxy' => ENV['http_proxy'] || ENV['HTTP_PROXY'],
        'HTTP_PROXY' => ENV['http_proxy'] || ENV['HTTP_PROXY'],
        'https_proxy' => ENV['https_proxy'] || ENV['HTTPS_PROXY'],
        'HTTPS_PROXY' => ENV['https_proxy'] || ENV['HTTPS_PROXY'],
        'UBUNTU_PROXY' => ENV['UBUNTU_PROXY'],
        'UBUNTU_MIRROR' => ENV['UBUNTU_MIRROR'],
        'DOCKER_MIRROR' => ENV['DOCKER_MIRROR'],
      }
      shell.inline = <<~BASH
        if ! mitamae version > /dev/null 2>&1; then
          install -o root -g root -m 0755 /vagrant/vendor/mitamae/mitamae-x86_64-linux /usr/local/bin/mitamae
        fi
        cd /vagrant
        mitamae local -y vendor/mitamae.yaml helpers/keeper.rb #{MITAMAE_COOKBOOKS.join(' ')}
      BASH
    end

    # Libvirt Provider Configuration
    domain.vm.provider :libvirt do |libvirt|
      # Enable Management Network
      libvirt.mgmt_attach = true
      # Memory
      libvirt.memory = 1024
      # Monitor
      libvirt.graphics_port = 5950
    end
  end

  # Gateway Server
  config.vm.define :gateway do |domain|
    # Libvirt Provider Configuration
    domain.vm.provider :libvirt do |libvirt|
      # Memory
      libvirt.memory = 1024
      # Monitor
      libvirt.graphics_port = 5951
      # PXE Boot
      libvirt.boot 'network'
    end
  end
end
