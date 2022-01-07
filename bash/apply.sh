#!/bin/bash
# check if TF is installed
# check if jq is installed
echo -n "vsphere server FQDN: "
read -r vsphere_server
echo -n "vsphere username: "
read -r vsphere_username
echo -n "vsphere password: "
read -s vsphere_password
echo
curl https://raw.githubusercontent.com/tacobayle/bash/master/vcenter/get_vcenter.sh -o get_vcenter.sh
/bin/bash get_vcenter.sh $vsphere_server $vsphere_username $vsphere_password


