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
# dc
echo
echo "select vCenter dc..."
if [[ $(jq length datacenters.json) -eq 1 ]] ; then
  echo "defaulting to $(jq -r -c .[0] datacenters.json)"
else
  count=1
  for item in $(jq -c -r .[] networks.json)
  do
    echo "$count: $item"
    count=$((count+1))
  done
  until [ ! -z "$vcenter_dc" ] ; do echo -n "vcenter_dc number: " ; read -r vcenter_dc ; done
fi
# cluster
echo
echo "select vCenter cluster..."
if [[ $(jq length clusters.json) -eq 1 ]] ; then
  echo "defaulting to $(jq -r -c .[0] clusters.json)"
else
  count=1
  for item in $(jq -c -r .[] networks.json)
  do
    echo "$count: $item"
    count=$((count+1))
  done
  until [ ! -z "$vcenter_cluster" ] ; do echo -n "vcenter_cluster number: " ; read -r vcenter_cluster ; done
fi
# datastore
echo
echo "select vCenter datastore..."
if [[ $(jq length datastores.json) -eq 1 ]] ; then
  echo "defaulting to $(jq -r -c .[0] datastores.json)"
else
  count=1
  for item in $(jq -c -r .[] networks.json)
  do
    echo "$count: $item"
    count=$((count+1))
  done
  until [ ! -z "$vcenter_datastore" ] ; do echo -n "vcenter_datastore number: " ; read -r vcenter_datastore ; done
fi
# management network
echo
echo "select vCenter management network..."
if [[ $(jq length networks.json) -eq 1 ]] ; then
  echo "defaulting to $(jq -r -c .[0] networks.json)"
else
  count=1
  IFS=$'\n'
  for item in $(jq -c -r .[] networks.json)
  do
    echo "$count: $item"
    count=$((count+1))
  done
  re='^[0-9]+$'
  until [[ $yournumber =~ $re ]] ; do echo -n "network number: " ; read -r yournumber ; done
  #yournumber=$((yournumber-1))
  echo $yournumber
  vcenter_network_mgmt_name=$(jq -r -c .[$yournumber] networks.json)
  echo $vcenter_network_mgmt_name
fi