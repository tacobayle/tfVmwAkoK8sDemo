#!/bin/bash
# check if TF is installed
# check if jq is installed
run_cmd() {
  retry=10
  pause=20
  attempt=0
  echo "############################################################################################"
  while [ $attempt -ne $retry ]; do
    if eval "$@"; then
      echo "$1 PASSED"
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
read -r vsphere_server
echo -n "vsphere username: "
read -r vsphere_username
echo -n "vsphere password: "
read -s vsphere_password
echo
run_cmd 'curl https://raw.githubusercontent.com/tacobayle/bash/master/vcenter/get_vcenter.sh -o get_vcenter.sh --silent ; test $(ls -l get_vcenter.sh | awk '"'"'{print $5}'"'"') -gt 0'
/bin/bash get_vcenter.sh $vsphere_server $vsphere_username $vsphere_password

