#!/bin/bash
# check if TF is installed
# check if jq is installed
run_cmd() {
  retry=10
  pause=20
  attempt=0
  while [ $attempt -ne $retry ]; do
    if eval "$@"; then
      break
    else
      echo "$1 FAILED"
    fi
    ((attempt++))
    sleep $pause
    if [ $attempt -eq $retry ]; then
      echo "$1 FAILED after $retry retries" | tee /tmp/cloudInitFailed.log
      exit 255
    fi
    done
}
until [ ! -z "$vsphere_server" ] ; do echo -n "vsphere server FQDN: " ; read -r vsphere_server ; done
until [ ! -z "$vsphere_username" ] ; do echo -n "vsphere username: " ; read -r vsphere_username ; done
until [ ! -z "$vsphere_password" ] ; do echo -n "vsphere password: " ; read -s vsphere_password ; echo ; done
#read -s vsphere_password
#echo
run_cmd 'curl https://raw.githubusercontent.com/tacobayle/bash/master/vcenter/get_vcenter.sh -o get_vcenter.sh --silent ; test $(ls -l get_vcenter.sh | awk '"'"'{print $5}'"'"') -gt 0'
/bin/bash get_vcenter.sh $vsphere_server $vsphere_username $vsphere_password
clear
# dc
echo
echo "select vCenter dc..."
if [[ $(jq length datacenters.json) -eq 1 ]] ; then
  echo "defaulting to $(jq -r -c .[0] datacenters.json)"
  sleep 2
  vcenter_dc=$(jq -r -c .[0] datacenters.json)
else
  count=1
  IFS=$'\n'
  for item in $(jq -c -r .[] networks.json)
  do
    echo "$count: $item"
    count=$((count+1))
  done
  re='^[0-9]+$' ; yournumber=""
  until [ ! -z "$vcenter_dc" ] ; do echo -n "vcenter_dc number: " ; read -r vcenter_dc ; done
  yournumber=$((yournumber-1))
  vcenter_dc=$(jq -r -c .[$yournumber] datacenters.json)
fi
clear
# cluster
echo
echo "select vCenter cluster..."
if [[ $(jq length clusters.json) -eq 1 ]] ; then
  echo "defaulting to $(jq -r -c .[0] clusters.json)"
  sleep 2
  vcenter_cluster=$(jq -r -c .[0] clusters.json)
else
  count=1
  IFS=$'\n'
  for item in $(jq -c -r .[] clusters.json)
  do
    echo "$count: $item"
    count=$((count+1))
  done
  re='^[0-9]+$' ; yournumber=""
  until [[ $yournumber =~ $re ]] ; do echo -n "cluster number: " ; read -r yournumber ; done
  yournumber=$((yournumber-1))
  vcenter_cluster=$(jq -r -c .[$yournumber] clusters.json)
fi
clear
# datastore
echo
echo "select vCenter datastore..."
if [[ $(jq length datastores.json) -eq 1 ]] ; then
  echo "defaulting to $(jq -r -c .[0] datastores.json)"
  sleep 2
  vcenter_datastore=$(jq -r -c .[0] datastores.json)
else
  count=1
  IFS=$'\n'
  for item in $(jq -c -r .[] datastores.json)
  do
    echo "$count: $item"
    count=$((count+1))
  done
  re='^[0-9]+$' ; yournumber=""
  until [[ $yournumber =~ $re ]] ; do echo -n "datastore number: " ; read -r yournumber ; done
  yournumber=$((yournumber-1))
  vcenter_datastore=$(jq -r -c .[$yournumber] datastores.json)
fi
clear
# management network
echo
echo "select vCenter management network..."
if [[ $(jq length networks.json) -eq 1 ]] ; then
  echo "defaulting to $(jq -r -c .[0] networks.json)"
  sleep 2
  vcenter_network_mgmt_name=$(jq -r -c .[0] networks.json)
else
  count=1
  IFS=$'\n'
  for item in $(jq -c -r .[] networks.json)
  do
    echo "$count: $item"
    count=$((count+1))
  done
  re='^[0-9]+$' ; yournumber=""
  until [[ $yournumber =~ $re ]] ; do echo -n "network number: " ; read -r yournumber ; done
  yournumber=$((yournumber-1))
  vcenter_network_mgmt_name=$(jq -r -c .[$yournumber] networks.json)
fi
clear
# management network dhcp
until [[ $dhcp == "y" ]] || [[ $dhcp == "n" ]] ; do echo -n "dhcp for management network y/n: " ; read -r dhcp ; done
if [[ $dhcp == "y" ]] ; then
  dhcp="true"
fi
if [[ $dhcp == "n" ]] ; then
  dhcp="false"
  until [ ! -z "$vcenter_network_mgmt_network_cidr" ] ; do echo -n "enter management network address cidr (like: 10.206.112.0/22): " ; read -r vcenter_network_mgmt_network_cidr ; done
  until [ ! -z "$vcenter_network_mgmt_ip4_addresses" ] ; do echo -n "enter 6 free IPs separated by commas to use in the management network (like: 10.206.112.70, 10.206.112.71, 10.206.112.72, 10.206.112.73, 10.206.112.74, 10.206.112.75): " ; read -r vcenter_network_mgmt_ip4_addresses ; done
  until [ ! -z "$vcenter_network_mgmt_network_dns" ] ; do echo -n "enter DNS IPs separated by commas (like: 10.206.8.130, 10.206.8.131): " ; read -r vcenter_network_mgmt_network_dns ; done
  until [ ! -z "$vcenter_network_mgmt_gateway4" ] ; do echo -n "enter IP of the default gateway (like: 10.206.112.1): " ; read -r vcenter_network_mgmt_gateway4 ; done
  until [ ! -z "$vcenter_network_mgmt_ipam_pool" ] ; do echo -n "enter a range of at least two IPs for management network separated by hyphen (like: 10.206.112.55 - 10.206.112.57): " ; read -r vcenter_network_mgmt_ipam_pool ; done
fi
echo -n "enter NTP IPs separated by commas (like: 10.206.8.130, 10.206.8.131) - type enter to ignore: " ; read -r ntp_servers_ips
clear
# vip network
echo
echo "select vCenter vip network..."
if [[ $(jq length networks.json) -eq 1 ]] ; then
  echo "defaulting to $(jq -r -c .[0] networks.json)"
  sleep 2
  vcenter_network_vip_name=$(jq -r -c .[0] networks.json)
else
  count=1
  IFS=$'\n'
  for item in $(jq -c -r .[] networks.json)
  do
    echo "$count: $item"
    count=$((count+1))
  done
  re='^[0-9]+$' ; yournumber=""
  until [[ $yournumber =~ $re ]] ; do echo -n "network number: " ; read -r yournumber ; done
  yournumber=$((yournumber-1))
  vcenter_network_vip_name=$(jq -r -c .[$yournumber] networks.json)
fi
clear
# vip network details
until [ ! -z "$vcenter_network_vip_cidr" ] ; do echo -n "enter vip network address cidr (like: 10.206.112.0/22): " ; read -r vcenter_network_vip_cidr ; done
until [ ! -z "$vcenter_network_vip_ip4_addresses" ] ; do echo -n "enter a free IPs to use in the vip network (like: 10.1.100.200): " ; read -r vcenter_network_vip_ip4_addresses ; done
until [ ! -z "$vcenter_network_vip_ipam_pool" ] ; do echo -n "enter a range of IPs for vip network separated by hyphen (like: 10.1.100.100 - 10.1.100.199): " ; read -r vcenter_network_vip_ipam_pool ; done
clear
# k8s network
echo
echo "select vCenter vip network..."
if [[ $(jq length networks.json) -eq 1 ]] ; then
  echo "defaulting to $(jq -r -c .[0] networks.json)"
  sleep 2
  vcenter_network_k8s_name=$(jq -r -c .[0] networks.json)
else
  count=1
  IFS=$'\n'
  for item in $(jq -c -r .[] networks.json)
  do
    echo "$count: $item"
    count=$((count+1))
  done
  re='^[0-9]+$' ; yournumber=""
  until [[ $yournumber =~ $re ]] ; do echo -n "network number: " ; read -r yournumber ; done
  yournumber=$((yournumber-1))
  vcenter_network_k8s_name=$(jq -r -c .[$yournumber] networks.json)
fi
clear
# k8s network details
until [ ! -z "$vcenter_network_k8s_cidr" ] ; do echo -n "enter K8s network address cidr (like: 10.206.112.0/22): " ; read -r vcenter_network_k8s_cidr ; done
until [ ! -z "$vcenter_network_k8s_ip4_addresses" ] ; do echo -n "enter 3 free IPs separated by commas to use in the k8s network (like: 100.100.100.200, 100.100.100.201, 100.100.100.202): " ; read -r vcenter_network_k8s_ip4_addresses ; done
until [ ! -z "$vcenter_network_k8s_ipam_pool" ] ; do echo -n "enter a range of IPs for vip network separated by hyphen (like: 100.100.100.100 - 100.100.100.199): " ; read -r vcenter_network_k8s_ipam_pool ; done
clear
# Avi version
echo
echo "select Avi version..."
if [[ $(jq length avi_versions.json) -eq 1 ]] ; then
  echo "defaulting to $(jq -r -c .[0] avi_versions.json)"
  sleep 2
  avi_version=$(jq -r -c .[0] avi_versions.json)
else
  count=1
  IFS=$'\n'
  for item in $(jq -c -r .[] avi_versions.json)
  do
    echo "$count: $item"
    count=$((count+1))
  done
  re='^[0-9]+$' ; yournumber=""
  until [[ $yournumber =~ $re ]] ; do echo -n "Avi version number: " ; read -r yournumber ; done
  yournumber=$((yournumber-1))
  avi_version=$(jq -r -c .[$yournumber] avi_versions.json)
fi
clear
#
until [ ! -z "$avi_domain" ] ; do echo -n "enter a domain name (like: avi.com): " ; read -r avi_domain ; done
# CNI
echo
echo "select CNI..."
if [[ $(jq length cnis.json) -eq 1 ]] ; then
  echo "defaulting to $(jq -r -c .[0] cnis.json)"
  sleep 2
  K8s_cni_name=$(jq -r -c .[0] cnis.json)
else
  count=1
  IFS=$'\n'
  for item in $(jq -c -r .[] cnis.json)
  do
    echo "$count: $item"
    count=$((count+1))
  done
  re='^[0-9]+$' ; yournumber=""
  until [[ $yournumber =~ $re ]] ; do echo -n "CNI number: " ; read -r yournumber ; done
  yournumber=$((yournumber-1))
  K8s_cni_name=$(jq -r -c .[$yournumber] cnis.json)
fi
clear
# svc type
echo
echo "select service type..."
if [[ $(jq length svc_types.json) -eq 1 ]] ; then
  echo "defaulting to $(jq -r -c .[0] svc_types.json)"
  sleep 2
  ako_service_type=$(jq -r -c .[0] svc_types.json)
else
  if [[ $K8s_cni_name == "antrea" ]] ; then
    count=1
    IFS=$'\n'
    for item in $(jq -c -r .[] svc_types.json)
    do
      echo "$count: $item"
      count=$((count+1))
    done
    re='^[0-9]+$' ; yournumber=""
    until [[ $yournumber =~ $re ]] ; do echo -n "svc type: " ; read -r yournumber ; done
    yournumber=$((yournumber-1))
    ako_service_type=$(jq -r -c .[$yournumber] svc_types.json)
  fi
  if [[ $K8s_cni_name == "calico" ]] || [[ $K8s_cni_name == "flannel" ]] ; then
    ako_service_type="ClusterIP"
  fi
fi
clear
# Ako version
echo
echo "select AKO version..."
if [[ $(jq length ako_versions.json) -eq 1 ]] ; then
  echo "defaulting to $(jq -r -c .[0] ako_versions.json)"
  sleep 2
  ako_version=$(jq -r -c .[0] ako_versions.json)
else
  count=1
  IFS=$'\n'
  for item in $(jq -c -r .[] ako_versions.json)
  do
    echo "$count: $item"
    count=$((count+1))
  done
  re='^[0-9]+$' ; yournumber=""
  until [[ $yournumber =~ $re ]] ; do echo -n "CNI number: " ; read -r yournumber ; done
  yournumber=$((yournumber-1))
  ako_version=$(jq -r -c .[$yournumber] ako_versions.json)
fi
clear
# ako deploy
until [[ $ako_deploy == "y" ]] || [[ $ako_deploy == "n" ]] ; do echo -n "deploy AKO automatically y/n: " ; read -r ako_deploy ; done
clear
# avi url
until [ ! -z "$avi_controller_url" ] ; do echo -n "Avi download URL: " ; read -r avi_controller_url ; done
echo $vcenter_dc
echo $vcenter_cluster
echo $vcenter_datastore
echo $vcenter_network_mgmt_name
echo $dhcp
echo $vcenter_network_mgmt_ip4_addresses
echo $vcenter_network_mgmt_network_cidr
echo $vcenter_network_mgmt_network_dns
echo $vcenter_network_mgmt_gateway4
echo $vcenter_network_mgmt_ipam_pool
echo $ntp_servers_ips
echo $vcenter_network_vip_name
echo $vcenter_network_vip_cidr
echo $vcenter_network_vip_ip4_addresses
echo $vcenter_network_vip_ipam_pool
echo $vcenter_network_k8s_name
echo $vcenter_network_k8s_cidr
echo $vcenter_network_k8s_ip4_addresses
echo $vcenter_network_k8s_ipam_pool
echo $K8s_cni_name
echo $ako_service_type
echo $ako_version
echo $avi_version
echo $avi_controller_url