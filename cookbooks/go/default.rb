version = '1.12.1'
sha256sum = '2a3fdabf665496a0db5f41ec6af7a9b15a49fbe71a85a50ca38b1f13a103aeec'

if File.exist?('/usr/local/go/bin/go') then
  check_version = run_command('/usr/local/go/bin/go version', error: false)

  if check_version.success? then
    installed_version = check_version.stdout.lines[0].gsub(/^go version go([0-9]+\.[0-9]+\.[0-9]+).*$/, '\1').chomp

    if installed_version != version then
      directory '/usr/local/go' do
        action :delete
      end
    end
  end
end

http_request "/tmp/go#{version}.linux-amd64.tar.gz" do
  url "https://dl.google.com/go/go#{version}.linux-amd64.tar.gz"
  not_if [
    'test -d /usr/local/go',
    "echo #{sha256sum} /tmp/go#{version}.linux-amd64.tar.gz | sha256sum -c --ignore-missing --status",
  ].join(' || ')
  check_error true
end

execute "tar -xvf /tmp/go#{version}.linux-amd64.tar.gz" do
  cwd '/usr/local'
  not_if 'test -d /usr/local/go'
end

file "/tmp/go#{version}.linux-amd64.tar.gz" do
  action :delete
  only_if 'test -d /usr/local/go'
end

remote_file '/etc/profile.d/go-path.sh' do
  owner 'root'
  group 'root'
  mode  '0644'
end

unless ENV['PATH'].include?('/usr/local/go/bin') then
  ENV['PATH'] << ':/usr/local/go/bin'
end
