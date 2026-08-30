# frozen_string_literal: true

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
apt-get update
apt-get upgrade -y
apt-get install -y unattended-upgrades ansible python3-debian
echo 'unattended-upgrades unattended-upgrades/enable_auto_updates boolean false' | debconf-set-selections
dpkg-reconfigure -f noninteractive unattended-upgrades
apt-get autoremove -y
EOF

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Iteração com os servidores do ambiente
  env.each do |env|
    config.vm.define env['name'] do |srv|
      srv.vm.box      = "bento/ubuntu-24.04"
      srv.vm.box_version = "202510.26.0"
      srv.vm.hostname = env['hostname']
      srv.vm.network 'private_network', ip: env['ipaddress']

      # Força a desmontagem do shared folder para prevenir que o systemd do Ubuntu 24.04 trave o reinicio e exija um
      # --force
      srv.trigger.before [:halt, :reload, :destroy] do |trigger|
        trigger.name = "Unmount synced folders before rebooting"
        trigger.run_remote = { inline: "sudo umount -f /vagrant || true" }
        trigger.on_error = :continue
      end

      if env['additional_interface'] == true
        srv.vm.network 'private_network', ip: '1.0.0.100',
          auto_config: false
      end

      # somente habilite isso se você estiver com o vbguest instalado e estiver com problemas para usar shared folders.
      srv.vbguest.auto_update = false

      srv.vm.provider 'virtualbox' do |vb|
        vb.name   = env['name']
        vb.memory = env['memory']
        vb.cpus   = env['cpus']
        vb.linked_clone = true
      end

      srv.vm.provision 'shell',
        inline: SCRIPT,
        privileged: true,
        env: {DEBIAN_FRONTEND: 'noninteractive'}

      srv.vm.provision 'ansible_local' do |ansible|
        ansible.playbook           = env['provision']
        ansible.become             = true
        ansible.become_user        = 'root'
        ansible.compatibility_mode = '2.0'
        ansible.install            = false
        ansible.install_mode       = :default
      end
    end
  end
end
