#
# Variables that can be changed
#
variable "vsphere_username" {}
variable "vsphere_password" {
//  sensitive = true
}

variable "docker_registry_username" {
  //  sensitive = true
}
variable "docker_registry_password" {
  //  sensitive = true
}
variable "docker_registry_email" {
  //  sensitive = true
}

variable "static_password" {
  default = null
}

variable "vsphere_server" {
  default = "wdc-06-vc12.oc.vmware.com"
}

variable "vcenter_dc" {
  default = "wdc-06-vc12"
}

variable "vcenter_cluster" {
  default = "wdc-06-vc12c01"
}

variable "vcenter_datastore" {
  default = "wdc-06-vc12c01-vsan"
}

variable "vcenter_folder" {
  default = "tf_ako_k8s_demo"
}

variable "vcenter_network_mgmt_name" {
  default = "vxw-dvs-34-virtualwire-3-sid-6120002-wdc-06-vc12-avi-mgmt"
}

variable "vcenter_network_mgmt_dhcp" {
  default = true
}

variable "vcenter_network_mgmt_ip4_addresses" {
  default = "10.206.112.70, 10.206.112.71, 10.206.112.72, 10.206.112.73, 10.206.112.74, 10.206.112.75"
}

variable "vcenter_network_mgmt_network_cidr" {
  default = "10.206.112.0/22"
}

variable "vcenter_network_mgmt_network_dns" {
  default = "10.206.8.130, 10.206.8.131"
}

variable "ntp_servers_ips" {
  default = "10.206.8.130, 10.206.8.131"
}

variable "vcenter_network_mgmt_gateway4" {
  default = "10.206.112.1"
}

variable "vcenter_network_mgmt_ipam_pool" {
  default = "10.206.112.55 - 10.206.112.57"
}

variable "vcenter_network_vip_name" {
  default = "vxw-dvs-34-virtualwire-120-sid-6120119-wdc-06-vc12-avi-dev116"
}

variable "vcenter_network_vip_cidr" {
  default = "10.1.100.0/24"
}

variable "vcenter_network_vip_ip4_address" {
  default = "10.1.100.200"
}

variable "vcenter_network_vip_ipam_pool" {
  default = "10.1.100.100 - 10.1.100.199"
}

variable "vcenter_network_k8s_name" {
  default = "vxw-dvs-34-virtualwire-116-sid-6120115-wdc-06-vc12-avi-dev112"
}

variable "vcenter_network_k8s_cidr" {
  default = "100.100.100.0/24"
}

variable "vcenter_network_k8s_ip4_addresses" {
  default = "100.100.100.200, 100.100.100.201, 100.100.100.202"
}

variable "vcenter_network_k8s_ipam_pool" {
  default = "100.100.100.100 - 100.100.100.199"
}

variable "avi_version" {
  default = "21.1.3"
}

variable "avi_domain" {
  default = "avi.com"
}

variable "K8s_version" {
  default = "1.21.3-00" # k8s version
}

variable "K8s_cni_name" {
  default = "calico"
}

variable "K8s_network_pod" {
  default = "192.168.0.0/16"
}

//variable "K8s_cni_url" {
//  default = "https://github.com/vmware-tanzu/antrea/releases/download/v1.2.3/antrea.yml"
//}

variable "Docker_version" {
  default = "5:20.10.7~3-0~ubuntu-focal"
}

variable "avi_controller_url" {}

variable "ako_helm_url" {
  default = "https://projects.registry.vmware.com/chartrepo/ako"
}

variable "ako_deploy" {
  default = false
}

variable "ako_version" {
  default = "1.6.1"
}

variable "ako_service_type" {
  default = "NodePortLocal"
}

//variable "vcenter_network_mgmt_cidr" {
//  default = "vxw-dvs-34-virtualwire-3-sid-6120002-wdc-06-vc12-avi-mgmt"
//}
//


//
//variable "vcenter_network_vip_cidr" {
//  default = "vxw-dvs-34-virtualwire-120-sid-6120119-wdc-06-vc12-avi-dev116"
//}






#
# Other Variables
#

variable "content_library" {
  default = {
    basename = "content_library_tf_"
    source_url_ubuntu_focal = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.ova"
  }
}

variable "controller" {
  default = {
    cpu = 8
    name = "ako-avi-controller"
    memory = 24768
    disk = 128
    wait_for_guest_net_timeout = 4
  }
}

variable "ssh_key" {
  type = map
  default = {
    algorithm            = "RSA"
    rsa_bits             = "4096"
    private_key_basename = "ssh_private_key"
    file_permission      = "0600"
  }
}

variable "destroy_env_vm" {
  type = map
  default = {
    name = "destroy-env-vm-"
    cpu = 2
    memory = 4096
    disk = 20
    wait_for_guest_net_timeout = 2
    template_name = "ubuntu-focal-20.04-cloudimg-template"
    username = "ubuntu"
//    if_name_main = "ens192"
    net_plan_file = "/etc/netplan/50-cloud-init.yaml"
  }
}

variable "client" {
  type = map
  default = {
    basename = "demo-client-"
    cpu = 2
    memory = 4096
    disk = 20
    wait_for_guest_net_timeout = 2
    username = "ubuntu"
    net_plan_file = "/etc/netplan/50-cloud-init.yaml"
//    if_name_main = "ens192"
//    if_name_second = "ens33"
  }
}

variable "ansible" {
  type = map
  default = {
    version = "2.10.7"
  }
}

variable "master" {
  type = map
  default = {
    basename = "master-tf-"
    username = "ubuntu"
    cpu = 2
//    if_name_main = "ens192"
//    if_name_second = "ens33"
    memory = 8192
    disk = 20
    net_plan_file = "/etc/netplan/50-cloud-init.yaml"
  }
}

variable "workers" {
  type = map
  default = {
    basename = "worker-tf-"
    username = "ubuntu"
    cpu = 2
//    if_name_main = "ens192"
//    if_name_second = "ens33"
    memory = 4096
    disk = 20
    net_plan_file = "/etc/netplan/50-cloud-init.yaml"
  }
}

//variable "worker" {
//  type = map
//  default = {
//    basename = "worker-tf-"
//    username = "ubuntu"
//    cpu = 2
//    if_name = "ens192"
//    memory = 4096
//    disk = 20
//    wait_for_guest_net_routable = "false"
//    net_plan_file = "/etc/netplan/50-cloud-init.yaml"
//  }
//}

//variable "vmw" {
//  default = {
//    name = "dc1_vCenter"
//    dhcp_enabled = "true"
//    domains = [
//      {
//        name = "avi.com"
//      }
//    ]
//    management_network = {
//      dhcp_enabled = "true"
//      exclude_discovered_subnets = "true"
//      vcenter_dvs = "true"
//    }
//    vip_network = {
//      vipIpStartPool = "200"
//      vipIpEndPool = "209"
//      seIpStartPool = "70"
//      seIpEndPool = "89"
//      type = "V4"
//      exclude_discovered_subnets = "true"
//      vcenter_dvs = "true"
//      dhcp_enabled = "no"
//    }
//    default_waf_policy = "System-WAF-Policy"
//    serviceEngineGroup = [
//      {
//        name = "Default-Group"
//        ha_mode = "HA_MODE_SHARED"
//        min_scaleout_per_vs = 2
//        buffer_se = 1
//      },
//    ]
//    virtualservices = {
//      dns = [
//        {
//          name = "app-dns"
//          services: [
//            {
//              port = 53
//            }
//          ]
//        }
//      ]
//    }
//    kubernetes = {
//      workers = {
//        count = 2
//      }
//      ako = {
//        deploy = false
//      }
//      clusters = [
//        {
//          name = "cluster1" # cluster name
//          netplanApply = true
//          username = "ubuntu" # default username dor docker and to connect
//          version = "1.21.3-00" # k8s version
//          namespaces = [
//            {
//              name= "ns1"
//            },
//            {
//              name= "ns2"
//            },
//            {
//              name= "ns3"
//            },
//          ]
//          ako = {
//            namespace = "avi-system"
//            version = "1.5.1"
//            helm = {
//              url = "https://projects.registry.vmware.com/chartrepo/ako"
//            }
//            values = {
//              AKOSettings = {
//                disableStaticRouteSync = "false"
//              }
//              L7Settings = {
//                serviceType = "ClusterIP"
//                shardVSSize = "SMALL"
//              }
//            }
//          }
//          serviceEngineGroup = {
//            name = "seg-cluster1"
//            ha_mode = "HA_MODE_SHARED"
//            min_scaleout_per_vs = "2"
//            buffer_se = 1
//            se_name_prefix = "cluster1"
//          }
//          networks = {
//            pod = "192.168.0.0/16"
//          }
//          docker = {
//            version = "5:20.10.7~3-0~ubuntu-bionic"
//          }
//          interface = "ens224" # interface used by k8s
//          cni = {
//            url = "https://docs.projectcalico.org/manifests/calico.yaml"
//            name = "calico" # calico or antrea
//          }
//          master = {
//            cpu = 8
//            memory = 16384
//            disk = 80
//            wait_for_guest_net_routable = "false"
//            template_name = "ubuntu-bionic-18.04-cloudimg-template"
//            net_plan_file = "/etc/netplan/50-cloud-init.yaml"
//          }
//          worker = {
//            cpu = 4
//            memory = 8192
//            disk = 40
//            wait_for_guest_net_routable = "false"
//            template_name = "ubuntu-bionic-18.04-cloudimg-template"
//            net_plan_file = "/etc/netplan/50-cloud-init.yaml"
//          }
//        },
//        {
//          name = "cluster2"
//          netplanApply = true
//          username = "ubuntu"
//          version = "1.21.3-00"
//          namespaces = [
//            {
//              name= "ns1"
//            },
//            {
//              name= "ns2"
//            },
//            {
//              name= "ns3"
//            },
//          ]
//          ako = {
//            namespace = "avi-system"
//            version = "1.5.1"
//            helm = {
//              url = "https://projects.registry.vmware.com/chartrepo/ako"
//            }
//            values = {
//              AKOSettings = {
//                disableStaticRouteSync = "false"
//              }
//              L7Settings = {
//                serviceType = "NodePortLocal"
//                shardVSSize = "SMALL"
//              }
//            }
//          }
//          serviceEngineGroup = {
//            name = "Default-Group"
//            ha_mode = "HA_MODE_SHARED"
//            min_scaleout_per_vs = 2
//            buffer_se = 1
//          }
//          networks = {
//            pod = "192.168.1.0/16"
//          }
//          docker = {
//            version = "5:20.10.7~3-0~ubuntu-bionic"
//          }
//          interface = "ens224"
//          cni = {
//            url = "https://github.com/vmware-tanzu/antrea/releases/download/v1.2.3/antrea.yml"
//            name = "antrea"
//            enableNPL = true
//          }
//          master = {
//            count = 1
//            cpu = 8
//            memory = 16384
//            disk = 80
//            wait_for_guest_net_routable = "false"
//            template_name = "ubuntu-bionic-18.04-cloudimg-template"
//            net_plan_file = "/etc/netplan/50-cloud-init.yaml"
//          }
//          worker = {
//            cpu = 4
//            memory = 8192
//            disk = 40
//            wait_for_guest_net_routable = "false"
//            template_name = "ubuntu-bionic-18.04-cloudimg-template"
//            net_plan_file = "/etc/netplan/50-cloud-init.yaml"
//          }
//        }
//      ]
//    }
//  }
//}