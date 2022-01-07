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
echo -n "vsphere server FQDN: "
until [ ! -z "$vsphere_server" ] ; do read -r vsphere_server ; done
echo -n "vsphere username: "
until [ ! -z "$vsphere_username" ] ; do read -r vsphere_username ; done
echo -n "vsphere password: "
until [ ! -z "$vsphere_password" ] ; do read -s vsphere_password ; echo ; done
#read -s vsphere_password
#echo
run_cmd 'curl https://raw.githubusercontent.com/tacobayle/bash/master/vcenter/get_vcenter.sh -o get_vcenter.sh --silent ; test $(ls -l get_vcenter.sh | awk '"'"'{print $5}'"'"') -gt 0'
/bin/bash get_vcenter.sh $vsphere_server $vsphere_username $vsphere_password

