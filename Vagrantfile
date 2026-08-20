# -*- mode: ruby -*-
# vi: set ft=ruby :

# Variaveis
VAGRANTFILE_API_VERSION = 2

# Chamando modulo YAML
require 'yaml'

# Lendo o arquivo YAML com as configuracoes do ambiente
env = YAML.load_file('environment.yaml')

# Limitando apenas a ultima versao estavel do Vagrant instalada
Vagrant.require_version '>= 2.0.0'

SCRIPT = <<-EOF
echo 'unattended-upgrades unattended-upgrades/enable_auto_updates boolean false' | sudo debconf-set-selections
apt-get update
apt-get upgrade -y
apt-get autoremove -y
dpkg-reconfigure -f noninteractive unattended-upgrades
EOF

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Iteracao com os servidores do ambiente
  env.each do |env|
    config.vm.define env['name'] do |srv|
      srv.vm.box      = env['box']
      srv.vm.hostname = env['hostname']
      srv.vm.network 'private_network', ip: env['ipaddress']

      if env['additional_interface'] == true
        srv.vm.network 'private_network', ip: '1.0.0.100',
          auto_config: false
      end

      srv.vbguest.auto_update = true

      srv.vm.provider 'virtualbox' do |vb|
        vb.name   = env['name']
        vb.memory = env['memory']
        vb.cpus   = env['cpus']
        vb.linked_clone = true
      end

      srv.vm.provision 'shell',
        inline: SCRIPT,
        env: {DEBIAN_FRONTEND: 'noninteractive'}

      srv.vm.provision 'ansible_local' do |ansible|
        ansible.playbook           = env['provision']
        ansible.install_mode       = 'pip'
        ansible.become             = true
        ansible.become_user        = 'root'
        ansible.compatibility_mode = '2.0'
      end
    end
  end
end
