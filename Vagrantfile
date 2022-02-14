# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "generic/debian11"
  config.vm.network "forwarded_port", guest: 8001, host: 8001
  config.vm.network "forwarded_port", guest: 8002, host: 8002
  config.vm.network "forwarded_port", guest: 8003, host: 8003
  config.vm.provider "virtualbox" do |vb|
    vb.name = "dab_tx"
    vb.memory = "3072"
    vb.cpus = "3"
    vb.customize ['modifyvm', :id, '--usbxhci', 'on']
  end
end