# Tests

## passed
### dhcp


- vcenter_network_mgmt_dhcp: true, avi_version: 21.1.3, cni: antrea, ako_service_type: ClusterIP

### static

- vcenter_network_mgmt_dhcp: false, avi_version: 21.1.3, cni: antrea, ako_service_type: ClusterIP



## on-going

### dhcp

- vcenter_network_mgmt_dhcp: true, avi_version: 21.1.3, cni: calico, ako_service_type: ClusterIP

## to be done

### dhcp

- v1.64: vcenter_network_mgmt_dhcp: true, avi_version: 21.1.3, cni: calico, ako_service_type: ClusterIP
- v1.68: vcenter_network_mgmt_dhcp: true, avi_version: 21.1.3, cni: flannel, ako_service_type: ClusterIP
- vcenter_network_mgmt_dhcp: true, avi_version: 21.1.3, cni: antrea, ako_service_type: NodePortLocal

### static


- vcenter_network_mgmt_dhcp: false, avi_version: 21.1.3, cni: antrea, ako_service_type: NodePortLocal
- vcenter_network_mgmt_dhcp: false, avi_version: 21.1.3, cni: calico
- vcenter_network_mgmt_dhcp: false, avi_version: 21.1.3, cni: flannel