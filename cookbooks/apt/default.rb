if ENV['UBUNTU_PROXY'] then
  file '/etc/apt/apt.conf' do
    action :create
    content "Acquire::http::proxy \"#{ENV['UBUNTU_PROXY']}\";"
  end
else
  file '/etc/apt/apt.conf' do
    action :delete
  end
end

apt_repository 'Ubuntu Official Repository' do
  path '/etc/apt/sources.list'
  entry [
    {
      :default_uri => 'http://jp.archive.ubuntu.com/ubuntu',
      :mirror_uri  => "#{ENV['UBUNTU_MIRROR']}",
      :suite       => '###platform_codename###',
      :source      => true,
      :components  => [
        'main',
        'restricted',
        'universe',
        'multiverse',
      ],
    },
    {
      :default_uri => 'http://jp.archive.ubuntu.com/ubuntu',
      :mirror_uri  => "#{ENV['UBUNTU_MIRROR']}",
      :suite       => '###platform_codename###-updates',
      :source      => true,
      :components  => [
        'main',
        'restricted',
        'universe',
        'multiverse',
      ],
    },
    {
      :default_uri => 'http://jp.archive.ubuntu.com/ubuntu',
      :mirror_uri  => "#{ENV['UBUNTU_MIRROR']}",
      :suite       => '###platform_codename###-backports',
      :source      => true,
      :components  => [
        'main',
        'restricted',
        'universe',
        'multiverse',
      ],
    },
    {
      :default_uri => 'http://jp.archive.ubuntu.com/ubuntu',
      :mirror_uri  => "#{ENV['UBUNTU_MIRROR']}",
      :suite       => '###platform_codename###-security',
      :source      => true,
      :components  => [
        'main',
        'restricted',
        'universe',
        'multiverse',
      ],
    },
  ]
  notifies :run, 'execute[update repository]', :immediately
end

execute 'update repository' do
  action :nothing
  command 'apt-get update'
end

execute 'update repository' do
  command 'apt-get update'
  only_if 'test -z "$(find -H /var/lib/apt/lists -maxdepth 0 -mmin -3600)"'
end

execute 'upgrade distribution' do
  action :nothing
  command 'env DEBIAN_FRONTEND="noninteractive" apt-get -y dist-upgrade'
  subscribes :run, 'execute[update repository]', :immediately
end
