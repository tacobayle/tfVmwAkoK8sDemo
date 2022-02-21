# Tests

## dhcp

- vcenter_network_mgmt_dhcp: true, avi_version: 21.1.2, cni: antrea, ako_service_type: NodePortLocal, ako_deploy: false
- vcenter_network_mgmt_dhcp: true, avi_version: 21.1.2, cni: antrea, ako_service_type: NodePortLocal, ako_deploy: true
- vcenter_network_mgmt_dhcp: true, avi_version: 21.1.2, cni: antrea, ako_service_type: ClusterIP, ako_deploy: false
- vcenter_network_mgmt_dhcp: true, avi_version: 21.1.2, cni: antrea, ako_service_type: ClusterIP, ako_deploy: true
- vcenter_network_mgmt_dhcp: true, avi_version: 21.1.2, cni: calico, ako_service_type: ClusterIP, ako_deploy: false
- vcenter_network_mgmt_dhcp: true, avi_version: 21.1.2, cni: calico, ako_service_type: ClusterIP, ako_deploy: true
- vcenter_network_mgmt_dhcp: true, avi_version: 21.1.2, cni: flannel, ako_service_type: ClusterIP, ako_deploy: false
- vcenter_network_mgmt_dhcp: true, avi_version: 21.1.2, cni: flannel, ako_service_type: ClusterIP, ako_deploy: true

## static

- vcenter_network_mgmt_dhcp: false, avi_version: 21.1.2, cni: antrea, ako_service_type: NodePortLocal, ako_deploy: false
- vcenter_network_mgmt_dhcp: false, avi_version: 21.1.2, cni: antrea, ako_service_type: NodePortLocal, ako_deploy: true
- vcenter_network_mgmt_dhcp: false, avi_version: 21.1.2, cni: antrea, ako_service_type: ClusterIP, ako_deploy: false
- vcenter_network_mgmt_dhcp: false, avi_version: 21.1.2, cni: antrea, ako_service_type: ClusterIP, ako_deploy: true
- vcenter_network_mgmt_dhcp: false, avi_version: 21.1.2, cni: calico, ako_service_type: ClusterIP, ako_deploy: false
- vcenter_network_mgmt_dhcp: false, avi_version: 21.1.2, cni: calico, ako_service_type: ClusterIP, ako_deploy: true
- vcenter_network_mgmt_dhcp: false, avi_version: 21.1.2, cni: flannel, ako_service_type: ClusterIP, ako_deploy: false
- vcenter_network_mgmt_dhcp: false, avi_version: 21.1.2, cni: flannel, ako_service_type: ClusterIP, ako_deploy: true