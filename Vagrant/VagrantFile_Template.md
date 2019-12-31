# File template vagrant
paste to VagrantFile

## 1. Tạo 1 server
```bash
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-16.04"
  config.ssh.insert_key = false
  config.vm.synced_folder ".", "/vagrant", id: "vagrant"
  config.vm.synced_folder "./apps", "/home/vagrant/apps", id: "apps"
  config.vm.provider :virtualbox do |v|
    v.memory = 2048
    v.linked_clone = true
    v.cpus = 2
  end

  config.vm.define "app" do |app|
    app.vm.hostname = "app.test"
    app.vm.network :private_network, ip: "192.168.60.4"
  end
end
```

- config.vm.box : thay bằng image của os muốn tạo
- config.ssh.insert_key : trường hợp muốn tạo ssh publickey sau khi OS được tạo xong, nếu điền false, sẽ không cần path tới file public key
- config.vm.synced_folder : đồng bộ data giữa máy chủ thật, và server ảo được tạo
- id : định danh trong vagrant cho image, mỗi 1 id sẽ được cung cấp bởi duy nhất 1 provider (virtualbox, hyperv, kvm)
- config.vm.provider :virtualbox : lựa chọn provider là virtualbox
- v.memory : khai báo RAM cho máy ảo
- v.cpus : khai báo nhân CPU cho máy ảo
- config.vm.define : khai báo tên của image (1 id có thể có nhiều tên). Có thể sử dụng tên này để ssh tới máy ảo. Ex `vagrant ssh app`
- app.vm.hostname : hostname sau khi máy ảo được tạo
- app.vm.network :private_network, ip : địa chỉ IP máy ảo

## 2. Tạo nhiều server cùng lúc

```bash
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-16.04"
  config.ssh.insert_key = false
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.provider :virtualbox do |v|
    v.memory = 1024
    v.linked_clone = true
    v.cpus = 2
  end

  config.vm.define "app1" do |app|
    app.vm.hostname = "app1.test"
    app.vm.network :private_network, ip: "192.168.60.4"
  end

  config.vm.define "app2" do |app|
    app.vm.hostname = "app2.test"
    app.vm.network :private_network, ip: "192.168.60.5"
  end

  config.vm.define "db" do |db|
    db.vm.hostname = "db.test"
    db.vm.network :private_network, ip: "192.168.60.6"
  end
end
```