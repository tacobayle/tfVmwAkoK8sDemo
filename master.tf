data "template_file" "network_master_static" {
  count = (var.vcenter_network_mgmt_dhcp == false ? 1 : 0)
  template = file("templates/network_master_static.template")
  vars = {
    ip4_main = "${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[3]}/${split("/", var.vcenter_network_mgmt_network_cidr)[1]}"
    gw4 = var.vcenter_network_mgmt_gateway4
    dns = var.vcenter_network_mgmt_network_dns
    ip4_second = "${split(",", replace(var.vcenter_network_k8s_ip4_addresses, " ", ""))[0]}/${split("/", var.vcenter_network_k8s_cidr)[1]}"
  }
}

data "template_file" "network_master_dhcp_static" {
  count = (var.vcenter_network_mgmt_dhcp == true ? 1 : 0)
  template = file("templates/network_master_dhcp_static.template")
  vars = {
    ip4_second = "${split(",", replace(var.vcenter_network_k8s_ip4_addresses, " ", ""))[0]}/${split("/", var.vcenter_network_k8s_cidr)[1]}"
  }
}

data "template_file" "master_userdata_static" {
  template = file("${path.module}/userdata/master_static.userdata")
  count            = (var.vcenter_network_mgmt_dhcp == false ? 1 : 0)
  vars = {
    password      = var.static_password == null ? random_string.password.result : var.static_password
    net_plan_file = var.master.net_plan_file
    hostname = "${var.master.basename}${random_string.id.result}"
    network_config  = base64encode(data.template_file.network_master_static[count.index].rendered)
    K8s_version = var.K8s_version
    Docker_version = var.Docker_version
    K8s_network_pod = var.K8s_network_pod
    cni_name = var.K8s_cni_name
    ako_service_type = local.ako_service_type
    docker_registry_username = var.docker_registry_username
    docker_registry_password = var.docker_registry_password
  }
}

data "template_file" "master_userdata_dhcp" {
  template = file("${path.module}/userdata/master_dhcp.userdata")
  count            = (var.vcenter_network_mgmt_dhcp == true ? 1 : 0)
  vars = {
    password      = var.static_password == null ? random_string.password.result : var.static_password
    net_plan_file = var.master.net_plan_file
    hostname = "${var.master.basename}${random_string.id.result}"
    K8s_version = var.K8s_version
    Docker_version = var.Docker_version
    K8s_network_pod = var.K8s_network_pod
    network_config_static  = base64encode(data.template_file.network_master_dhcp_static[0].rendered)
    cni_name = var.K8s_cni_name
    ako_service_type = local.ako_service_type
    docker_registry_username = var.docker_registry_username
    docker_registry_password = var.docker_registry_password
  }
}

resource "vsphere_virtual_machine" "master" {
  name             = "${var.master.basename}${random_string.id.result}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = vsphere_folder.folder.path

  network_interface {
    network_id = data.vsphere_network.network_mgmt.id
  }

  num_cpus = var.master.cpu
  memory = var.master.memory
  guest_id = "ubuntu64Guest"

  disk {
    size             = var.master.disk
    label            = "master.lab_vmdk"
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
      hostname    = "${var.master.basename}-${random_string.id.result}"
      public-keys = chomp(tls_private_key.ssh.public_key_openssh)
      user-data   = var.vcenter_network_mgmt_dhcp == true ? base64encode(data.template_file.master_userdata_dhcp[0].rendered) : base64encode(data.template_file.master_userdata_static[0].rendered)
    }
  }

  connection {
    host        = var.vcenter_network_mgmt_dhcp == true ? self.default_ip_address : split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[3]
    type        = "ssh"
    agent       = false
    user        = var.master.username
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    inline      = [
      "while true ; do sleep 5 ; if [ -s \"/tmp/cloudInitFailed.log\" ] ; then exit 255 ; fi; if [ -s \"/tmp/cloudInitDone.log\" ] ; then exit ; fi ; done"
    ]
  }
}

resource "null_resource" "add_nic_to_master" {
  depends_on = [vsphere_virtual_machine.master]

  provisioner "local-exec" {
    command = <<-EOT
      export GOVC_USERNAME=${var.vsphere_username}
      export GOVC_PASSWORD=${var.vsphere_password}
      export GOVC_DATACENTER=${var.vcenter_dc}
      export GOVC_URL=${var.vsphere_server}
      export GOVC_CLUSTER=${var.vcenter_cluster}
      export GOVC_INSECURE=true
      /usr/local/bin/govc vm.network.add -vm "${var.master.basename}${random_string.id.result}" -net "${var.vcenter_network_k8s_name}"
    EOT
  }
}

resource "null_resource" "clear_ssh_key_locally_master" {
  provisioner "local-exec" {
    command = var.vcenter_network_mgmt_dhcp == true ? "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${vsphere_virtual_machine.master.default_ip_address}\" || true" : "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[3]}\" || true"
  }
}

data "template_file" "k8s_bootstrap_master" {
  template = file("${path.module}/templates/k8s_bootstrap_master.template")
  vars = {
    ip_k8s = split(",", replace(var.vcenter_network_k8s_ip4_addresses, " ", ""))[0]
    net_plan_file = var.master.net_plan_file
    docker_registry_username = var.docker_registry_username
    docker_registry_password = var.docker_registry_password
    cni_name = var.K8s_cni_name
    ako_service_type = local.ako_service_type
  }
}

resource "null_resource" "k8s_bootstrap_master" {
  connection {
    host = var.vcenter_network_mgmt_dhcp == true ? vsphere_virtual_machine.master.default_ip_address : split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[3]
    type = "ssh"
    agent = false
    user = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "local-exec" {
    command = "cat > k8s_bootstrap_master.sh <<EOL\n${data.template_file.k8s_bootstrap_master.rendered}\nEOL"
  }

  provisioner "file" {
    source = "k8s_bootstrap_master.sh"
    destination = "k8s_bootstrap_master.sh"
  }

  provisioner "remote-exec" {
    inline = ["sudo /bin/bash k8s_bootstrap_master.sh"]
  }

}

//resource "null_resource" "update_ip_to_master" {
//  depends_on = [null_resource.add_nic_to_master]
//
//  connection {
//    host        = var.vcenter_network_mgmt_dhcp == true ? vsphere_virtual_machine.master.default_ip_address : split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[3]
//    type        = "ssh"
//    agent       = false
//    user        = var.master.username
//    private_key = tls_private_key.ssh.private_key_pem
//  }
//
//  provisioner "remote-exec" {
//    inline = var.vcenter_network_mgmt_dhcp == true ? [
//      "if_secondary_name=$(sudo dmesg | grep eth0 | tail -1 | awk -F' ' '{print $5}' | sed 's/://')",
//      "sudo sed -i -e \"s/if_name_secondary_to_be_replaced/\"$if_secondary_name\"/g\" /tmp/50-cloud-init.yaml",
//      "sudo cp /tmp/50-cloud-init.yaml ${var.master.net_plan_file}",
//      "sudo netplan apply",
//      "sleep 10",
//      "sudo cp /etc/systemd/system/kubelet.service.d/10-kubeadm.conf /etc/systemd/system/kubelet.service.d/10-kubeadm.conf.old",
//      "ip=$(ip -f inet addr show $if_secondary_name | awk '/inet / {print $2}' | awk -F/ '{print $1}')",
//      "sudo sed '$${s/$/ --node-ip '$ip'/}' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf.old | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf",
//      "sudo systemctl daemon-reload",
//      "sudo systemctl restart kubelet"
//    ] : [
//      "if_secondary_name=$(sudo dmesg | grep eth0 | tail -1 | awk -F' ' '{print $5}' | sed 's/://')",
//      "sudo sed -i -e \"s/if_name_secondary_to_be_replaced/\"$if_secondary_name\"/g\" ${var.master.net_plan_file}",
//      "sudo netplan apply",
//      "sleep 10",
//      "sudo cp /etc/systemd/system/kubelet.service.d/10-kubeadm.conf /etc/systemd/system/kubelet.service.d/10-kubeadm.conf.old",
//      "ip=$(ip -f inet addr show $if_secondary_name | awk '/inet / {print $2}' | awk -F/ '{print $1}')",
//      "sudo sed '$${s/$/ --node-ip '$ip'/}' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf.old | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf",
//      "sudo systemctl daemon-reload",
//      "sudo systemctl restart kubelet"
//    ]
//  }
//}

resource "null_resource" "copy_join_command_to_tf" {
  depends_on = [null_resource.k8s_bootstrap_master, vsphere_virtual_machine.master]
  provisioner "local-exec" {
    command = var.vcenter_network_mgmt_dhcp == true ? "scp -i ~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem -o StrictHostKeyChecking=no ubuntu@${vsphere_virtual_machine.master.default_ip_address}:/home/ubuntu/join-command join-command" : "scp -i ~/.ssh/${var.ssh_key.private_key_basename}-${random_string.id.result}.pem -o StrictHostKeyChecking=no ubuntu@${split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[3]}:/home/ubuntu/join-command join-command"
  }
}

data "template_file" "K8s_sanity_check" {
  template = file("templates/K8s_check.sh.template")
  vars = {
    nodes = 3
  }
}

resource "null_resource" "K8s_sanity_check" {
  depends_on = [null_resource.join_cluster]

  connection {
    host = var.vcenter_network_mgmt_dhcp == true ? vsphere_virtual_machine.master.default_ip_address : split(",", replace(var.vcenter_network_mgmt_ip4_addresses, " ", ""))[3]
    type = "ssh"
    agent = false
    user = var.master.username
    private_key = tls_private_key.ssh.private_key_pem
  }

  provisioner "local-exec" {
    command = "cat > K8s_sanity_check.sh <<EOL\n${data.template_file.K8s_sanity_check.rendered}\nEOL"
  }

  provisioner "file" {
    source = "K8s_sanity_check.sh"
    destination = "K8s_sanity_check.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "/bin/bash K8s_sanity_check.sh",
    ]
  }
}