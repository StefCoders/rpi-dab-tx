# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Base image: Debian 12 (Bookworm) for newest packages
  config.vm.box = "debian/bookworm64"

  # Forward Supervisor + extra ports
  config.vm.network "forwarded_port", guest: 8001, host: 8001
  config.vm.network "forwarded_port", guest: 8002, host: 8002
  config.vm.network "forwarded_port", guest: 8003, host: 8003

  # Private network for internal access
  config.vm.network "private_network", ip: "192.168.56.10"

  # VM resources
  config.vm.provider "virtualbox" do |vb|
    vb.name = "dab_tx"
    vb.memory = 3072
    vb.cpus = 3
    vb.customize ['modifyvm', :id, '--usbxhci', 'on']
  end

  # Run installation script automatically
  config.vm.provision "shell", path: "install.sh"
end
