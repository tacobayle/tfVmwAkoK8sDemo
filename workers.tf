data "template_file" "network_workers_static" {
  count = (var.vcenter_network_mgmt_dhcp == false ? 2 : 0)
  template = file("templates/network_workers_static.template")
  vars = {
    if_name_main = var.workers.if_name_main
    if_name_second = var.workers.if_name_second
    ip4_main = "${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[4 + count.index]}/${split("/", var.vcenter_network_mgmt_network_cidr)[1]}"
    gw4 = var.vcenter_network_mgmt_gateway4
    dns = var.vcenter_network_mgmt_network_dns
    ip4_second = "${split(",", replace(var.vcenter_network_k8s_ip4_addresses, " ", ""))[1 + count.index]}/${split("/", var.vcenter_network_k8s_cidr)[1]}"
  }
}

data "template_file" "network_workers_dhcp" {
  count = (var.vcenter_network_mgmt_dhcp == true ? 2 : 0)
  template = file("templates/network_workers_dhcp.template")
  vars = {
    if_name_main = var.workers.if_name_main
    if_name_second = var.workers.if_name_second
    ip4_second = "${split(",", replace(var.vcenter_network_k8s_ip4_addresses, " ", ""))[1 + count.index]}/${split("/", var.vcenter_network_k8s_cidr)[1]}"
  }
}

data "template_file" "network_workers_dhcp_static" {
  count = (var.vcenter_network_mgmt_dhcp == true ? 2 : 0)
  template = file("templates/network_workers_dhcp_static.template")
  vars = {
    if_name_main = var.workers.if_name_main
    if_name_second = var.workers.if_name_second
    ip4_second = "${split(",", replace(var.vcenter_network_k8s_ip4_addresses, " ", ""))[1 + count.index]}/${split("/", var.vcenter_network_k8s_cidr)[1]}"
  }
}

data "template_file" "workers_userdata_static" {
  template = file("${path.module}/userdata/workers_static.userdata")
  count            = (var.vcenter_network_mgmt_dhcp == false ? 2 : 0)
  vars = {
    password      = var.static_password == null ? random_string.password.result : var.static_password
    net_plan_file = var.workers.net_plan_file
    hostname = "${var.workers.basename}-${count.index}-${random_string.id.result}"
    network_config  = base64encode(data.template_file.network_workers_static[count.index].rendered)
    K8s_version = var.K8s_version
    Docker_version = var.Docker_version
    if_name_k8s = var.workers.if_name_second
    cni_name = var.K8s_cni_name
    docker_registry_username = var.docker_registry_username
    docker_registry_password = var.docker_registry_password
  }
}

data "template_file" "workers_userdata_dhcp" {
  template = file("${path.module}/userdata/workers_dhcp.userdata")
  count            = (var.vcenter_network_mgmt_dhcp == true ? 2 : 0)
  vars = {
    password      = var.static_password == null ? random_string.password.result : var.static_password
    net_plan_file = var.workers.net_plan_file
    hostname = "${var.workers.basename}-${count.index}-${random_string.id.result}"
    network_config  = base64encode(data.template_file.network_workers_dhcp[count.index].rendered)
    K8s_version = var.K8s_version
    Docker_version = var.Docker_version
    network_config_static  = base64encode(data.template_file.network_workers_dhcp_static[count.index].rendered)
    if_name_k8s = var.workers.if_name_second
    cni_name = var.K8s_cni_name
    ako_service_type = local.ako_service_type
    docker_registry_username = var.docker_registry_username
    docker_registry_password = var.docker_registry_password
  }
}

resource "vsphere_virtual_machine" "workers" {
  count = 2
  name             = "${var.workers.basename}-${count.index}-${random_string.id.result}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folder.path

  network_interface {
    network_id = data.vsphere_network.network_mgmt.id
  }

  //  network_interface {
  //    network_id = data.vsphere_network.network_vip.id
  //  }


  num_cpus = var.workers.cpu
  memory = var.workers.memory
//  wait_for_guest_net_timeout = var.workers.wait_for_guest_net_timeout
  guest_id = "ubuntu64Guest"

  disk {
    size             = var.workers.disk
    label            = "workers.lab_vmdk"
    thin_provisioned = true
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = vsphere_content_library_item.file_ubuntu_focal.id
  }

  vapp {
    properties = {
      hostname    = "${var.workers.basename}-${random_string.id.result}-${count.index}"
      public-keys = chomp(tls_private_key.ssh.public_key_openssh)
      user-data   = var.vcenter_network_mgmt_dhcp == true ? base64encode(data.template_file.workers_userdata_dhcp[count.index].rendered) : base64encode(data.template_file.workers_userdata_static[count.index].rendered)
    }
  }

  connection {
    host        = var.vcenter_network_mgmt_dhcp == true ? self.default_ip_address : split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[4 + count.index]
    type        = "ssh"
    agent       = false
    user        = var.workers.username
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    inline      = [
      "while true ; do sleep 5 ; if [ -s \"/tmp/cloudInitFailed.log\" ] ; then exit 255 ; fi; if [ -s \"/tmp/cloudInitDone.log\" ] ; then exit ; fi ; done"
    ]
  }
}

resource "null_resource" "add_nic_to_workers" {
  depends_on = [vsphere_virtual_machine.workers]
  count = 2
  provisioner "local-exec" {
    command = <<-EOT
      export GOVC_USERNAME=${var.vsphere_username}
      export GOVC_PASSWORD=${var.vsphere_password}
      export GOVC_DATACENTER=${var.vcenter_dc}
      export GOVC_URL=${var.vsphere_server}
      export GOVC_CLUSTER=${var.vcenter_cluster}
      export GOVC_INSECURE=true
      /usr/local/bin/govc vm.network.add -vm "${var.workers.basename}-${count.index}-${random_string.id.result}" -net ${var.vcenter_network_k8s_name}
    EOT
  }
}

resource "null_resource" "clear_ssh_key_locally_workers" {
  count = 2
  provisioner "local-exec" {
    command = var.vcenter_network_mgmt_dhcp == true ? "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${vsphere_virtual_machine.workers[count.index].default_ip_address}\" || true" : "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[4 + count.index]}\" || true"
  }
}

resource "null_resource" "update_ip_to_workers" {
  depends_on = [null_resource.add_nic_to_workers]
  count = 2

  connection {
    host        = var.vcenter_network_mgmt_dhcp == true ? vsphere_virtual_machine.workers[count.index].default_ip_address : split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[4 + count.index]
    type        = "ssh"
    agent       = false
    user        = var.workers.username
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    inline = var.vcenter_network_mgmt_dhcp == true ? [
      "sudo cp /tmp/50-cloud-init.yaml ${var.workers.net_plan_file}",
      "sudo netplan apply",
      "sleep 10",
      "sudo cp /etc/systemd/system/kubelet.service.d/10-kubeadm.conf /etc/systemd/system/kubelet.service.d/10-kubeadm.conf.old",
      "ip=$(ip -f inet addr show ${var.workers.if_name_second} | awk '/inet / {print $2}' | awk -F/ '{print $1}')",
      "sudo sed '$${s/$/ --node-ip '$ip'/}' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf.old | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf",
      "sudo systemctl daemon-reload",
      "sudo systemctl restart kubelet"
    ] : [
      "sudo netplan apply",
      "sleep 10",
      "sudo cp /etc/systemd/system/kubelet.service.d/10-kubeadm.conf /etc/systemd/system/kubelet.service.d/10-kubeadm.conf.old",
      "ip=$(ip -f inet addr show ${var.master.if_name_second} | awk '/inet / {print $2}' | awk -F/ '{print $1}')",
      "sudo sed '$${s/$/ --node-ip '$ip'/}' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf.old | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf",
      "sudo systemctl daemon-reload",
      "sudo systemctl restart kubelet"
    ]
  }
}

resource "null_resource" "copy_join_command_to_workers" {
  count            = 2
  depends_on = [null_resource.copy_join_command_to_tf, vsphere_virtual_machine.workers]
  provisioner "local-exec" {
    command = var.vcenter_network_mgmt_dhcp == true ? "scp -i ~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem -o StrictHostKeyChecking=no join-command ubuntu@${vsphere_virtual_machine.workers[count.index].default_ip_address}:/home/ubuntu/join-command" : "scp -i ~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem -o StrictHostKeyChecking=no join-command ubuntu@${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[4 + count.index]}:/home/ubuntu/join-command"
  }
}

resource "null_resource" "join_cluster" {
  depends_on = [null_resource.copy_join_command_to_workers]
  count            = 2
  connection {
    host        = var.vcenter_network_mgmt_dhcp == true ? vsphere_virtual_machine.workers[count.index].default_ip_address : split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[4 + count.index]
    type        = "ssh"
    agent       = false
    user        = var.workers.username
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    inline      = [
      "sudo /bin/bash /home/ubuntu/join-command"
    ]
  }
}