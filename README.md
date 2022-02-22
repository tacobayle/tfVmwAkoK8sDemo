# tfVmwAkoK8sDemo

## Goal of this repo

This repo spin up a full Avi environment in vCenter with one K8s clusters in order to demonstrate AKO.

- K8s cluster can be configured with Antrea, Calico or Flanel as a CNI
- if CNI is antrea, AKO can rely on LocalNodePort or ClusterIP otherwise AKO will default to ClusterIP
- For the management network, every VM is using either IP DHCP allocation or static IP address
- For the K8s network, master and workers VMs are using static IP addresses and SE(s) will rely on Avi IPAM
- For the vip network, client VM is using static IP address and SE(s) will rely on Avi IPAM.

## Network diagram

![Alt text](img/tfVmwAkoK8sDemo.png?raw=true "Title")


## Prerequisites:

A VM which has terraform and govc installed:

```shellTerraform v1.0.6
on linux_amd64
+ provider registry.terraform.io/hashicorp/local v2.1.0
+ provider registry.terraform.io/hashicorp/null v3.1.0
+ provider registry.terraform.io/hashicorp/random v3.1.0
+ provider registry.terraform.io/hashicorp/template v2.2.0
+ provider registry.terraform.io/hashicorp/tls v3.1.0
+ provider registry.terraform.io/hashicorp/vsphere v2.0.2
```

```
https://github.com/vmware/govmomi/tree/master/govc
```

## clone this repo:

git clone https://github.com/tacobayle/tfVmwAkoK8sDemo

## Variables:

| Variable names        | Description           | Mandatory  | Example | variable source suggestion| 
| --------------------- |---------------------|:----------:|:--------|:--------|
| vsphere_username      | vsphere_username | true |administrator| environment variable |
| vsphere_password      | vsphere_password | true |******|environment variable |
| docker_registry_username | docker_registry_username      |    false |my_docker_login| environment variable |
| docker_registry_password | docker_registry_password      |    false |my_docker_password| environment variable |
| docker_registry_email | docker_registry_email      |    false |my_docker_email| environment variable |
| avi_controller_url | URL to download the OVA of Avi     |    true | "*****"|environment variable |
| vsphere_server | vsphere_server      |    true | wdc-06-vc12.oc.vmware.com| TF variable variable |
| vcenter_dc | vcenter_dc      |    true | wdc-06-vc12|TF variable variable |
| vcenter_cluster | vcenter_cluster      |    true | wdc-06-vc12c01|TF variable variable |
| vcenter_datastore | vcenter_datastore      |    true | wdc-06-vc12c01-vsan|TF variable variable |
| vcenter_folder | vcenter_folder where all the VMs will be stored      |    true | tf_ako_k8s_demo|TF variable variable |
| vcenter_network_mgmt_name | vcenter_network_mgmt_name      |    true | vxw-dvs-34-virtualwire-3-sid-6120002-wdc-06-vc12-avi-mgmt|TF variable variable |
| vcenter_network_mgmt_dhcp | Use dhcp for mgmt network?     |    true | true |TF variable variable |
| vcenter_network_mgmt_ip4_addresses | list of IP addresses separated by comma (if dhcp is disabled) - 6 IPs are required    |    true | "10.206.112.70, 10.206.112.71, 10.206.112.72, 10.206.112.73, 10.206.112.74, 10.206.112.75"|TF variable variable |
| vcenter_network_mgmt_network_cidr | vcenter_network_mgmt_network_cidr     |    true | "10.206.112.0/22"|TF variable variable |
| vcenter_network_mgmt_network_dns | vcenter_network_mgmt_network_dns to be configured in the Avi Controller     |    true | "10.206.8.130, 10.206.8.131"|TF variable variable |
| ntp_servers_ips | ntp_servers_ips to be configured in the Avi Controller     |    true | "10.206.8.130, 10.206.8.131"|TF variable variable |
| vcenter_network_mgmt_gateway4 | Default gateway of the management network     |    true | "10.206.112.1"|TF variable variable |
| vcenter_network_mgmt_ipam_pool | Avi IPAM pool to allocate IP for the Avi SE     |    true | "10.206.112.55 - 10.206.112.57"|TF variable variable |
| vcenter_network_vip_name | vcenter_network_vip_name     |    true | "vxw-dvs-34-virtualwire-120-sid-6120119-wdc-06-vc12-avi-dev116"|TF variable variable |
| vcenter_network_vip_cidr | vcenter_network_vip_cidr     |    true | "10.1.100.0/24"|TF variable variable |
| vcenter_network_vip_ip4_address | IP address of the client VM in the VIP network, make sure there is no conflict with vcenter_network_vip_ipam_pool     |    true | "10.1.100.200"|TF variable variable |
| vcenter_network_vip_ipam_pool | Avi IPAM pool to allocate IP for the Avi SE     |    true | "10.1.100.100 - 10.1.100.199"|TF variable variable |
| vcenter_network_k8s_name | vcenter_network_k8s_name     |    true | "vxw-dvs-34-virtualwire-116-sid-6120115-wdc-06-vc12-avi-dev112"|TF variable variable |
| vcenter_network_k8s_cidr | vcenter_network_k8s_cidr     |    true | "100.100.100.0/24"|TF variable variable |
| vcenter_network_k8s_ip4_addresses | list of IP addresses separated by comma - 3 IPs are required     |    true | "100.100.100.200, 100.100.100.201, 100.100.100.202"|TF variable variable |
| vcenter_network_k8s_ipam_pool | Avi IPAM pool to allocate IP for the Avi SE     |    true | "100.100.100.100 - 100.100.100.199"|TF variable variable |
| avi_version | Avi Version     |    true | "21.1.3"|TF variable variable |
| avi_domain | Avi Domain name     |    true | "avi.com"|TF variable variable |
| K8s_cni_name | CNI name: calico, flannel or antrea     |    true | "calico"|TF variable variable |
| ako_version | AKO version     |    true | "1.6.1"|TF variable variable |
| ako_service_type | AKO service type - used only for CNI antrea     |    true | "NodePortLocal"|TF variable variable |


## Use terraform apply to:

- Create a new folder within vCenter
- Create an admin (destroy_env_vm) VM within the vCenter folder attached to management network
- Create a client VM within the vCenter folder attached to management network and the vip network
- Create an Avi Controller VM within the vCenter folder attached to management network
- Create/Configure 2 a K8s cluster:
  - master and two worker nodes are attached to management network and k8s network
  - 1 master node per cluster
  - 2 workers nodes per cluster
- Configure Avi Controller:
  - Bootstrap Avi Controller (Password, NTP, DNS)
  - vCenter cloud configuration
  - Service Engine Groups
  - DNS VS is used in order to demonstrate FQDN registration reachable outside k8s cluster

## Run terraform:

- create:

```
terraform init
terraform apply -auto-approve
```

- destroy:

```
Use the command provided by terraform output
```

The terraform output should look similar to the following:

```
ssh -o StrictHostKeyChecking=no -i ~/.ssh/ssh_private_key-remo_ako.pem -t ubuntu@100.206.114.98 'cd aviAbsent ; ansible-playbook local.yml --extra-vars @~/.avicreds.json' ; sleep 5 ; terraform destroy -auto-approve
```

## Demonstrate AKO

- Warnings/Disclaimers:
  - the SE takes few minutes to come up
  - an alias has been created to use "k" instead of "kubectl" command
  - all the VS are reachable by connecting to the client vm using the FQDN of the VS
  - be patient when you try to test the app from the client VM: the DNS registration takes a bit of time
  - prior to deploying the ako on each single cluster, always make sure of the status (Ready) of the k8s clusters by using such command below:
  ```
  ubuntu@cluster1-master:~$ k get nodes
  NAME                STATUS   ROLES                  AGE     VERSION
  cluster1-master     Ready    control-plane,master   6d21h   v1.21.3
  cluster1-worker-1   Ready    <none>                 6d21h   v1.21.3
  cluster1-worker-2   Ready    <none>                 6d21h   v1.21.3
  ubuntu@cluster1-master:~$
  ```
- connect to one of the master node using ssh (username and password are part of the outputs)
- AKO installation (this can be done prior or during the demo)
  - on the master node: use the command generated by the "output of the Terraform" to be applied:
    ```
    helm install...
    ```
  - Verify that AKO POD has been created:
    ```shell
    k get pods -A
    ```
  
- K8s service (type LoadBalancer):  
  - Create a K8s service (type LoadBalancer):
    ```
    k apply -f service_loadBalancer.yml
    ``` 
  - Verify your K8s services:
    ```
    k get svc
    ```  
  - this triggers a new VS in the Avi controller

- K8s deployment:
  - Create a K8s deployment:
    ```
    k apply -f deployment.yml
    ```
  - Verify your K8s deployment:
    ```
    k get deployment
    ```
  - you can check this new application by connecting/sshing to your client_demo VM and doing something like:
    ```shell
    curl web1.default.avi.com
    ```
    
- Scale your deployment:
  - scale your deployment using:  
    ```
    k scale deployment web-front1 --replicas=6
    ```
  - this triggers the pool to be scaled automatically for your Avi VS
- ingress (non HTTPS)
  - Create a K8s service (type ClusterIP):
    ```
    k apply -f service_clusterIP.yml
    ```
  - Verify your K8s services:
    ```
    k get svc
    ```  
  - Create an ingress:
    ```
    k apply -f ingress.yml
    ```
  - Verify your K8s ingress:
    ```shell
    k get ingress
    ```
  - this triggers a new VS (parent VS) in the Avi controller
  - you can check this new application by connecting/sshing to your client_demo VM and doing something like:
    ```
    curl ingress.avi.com
    ```
- Update ingress (non HTTPS) to HTTPS using a cert already configured in the Avi controller
  - Apply a host CRD rule:
    ```
    k apply -f avi_crd_hostrule_tls_cert.yml
    ```
  - Verify your host CRD rule status:
    ```shell
    k get HostRule avi-crd-hostrule-tls-cert -o json | jq .status.status
    ```
  - this triggers a new VS (child VS) in the Avi controller
  - you can check this new application by connecting/sshing to your client_demo VM and doing something like:
    ```
    curl -k https://ingress.avi.com
    ```
- ingress (HTTPS using an HTTPS certificate already configured in K8s cluster)
  - Create an ingress:
    ```
    k apply -f secure_ingress.yml
    ```
  - Verify your K8s ingress:
    ```shell
    k get ingress
    ```
  - this triggers a new VS (child VS) in the Avi controller
  - you can check this new application by connecting/sshing to your client_demo VM and doing something like:
    ```
    curl -k https://secure-ingress.avi.com
    ```
- Attach a WAF policy to the secure ingress previously created:
  - Apply a host CRD rule:
    ```
    k apply -f avi_crd_hostrule_waf.yml
    ```
  - Verify your host CRD rule status:
    ```shell
    k get HostRule  avi-crd-hostrule-waf -o json | jq .status.status
    ```  
  - this triggers a WAF policy which will be attached to the child VS in the Avi controller