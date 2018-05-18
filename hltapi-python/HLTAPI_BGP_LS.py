#################################
#
# File Name:         HLTAPI_BGP_LS.py
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup BGP-LS with OSPF.
#
# Test Step:         
#                   1. Reserve and connect chassis ports         
#                   2. Config BGP on Port1 & port2 with Link state NLRI
#                   3. Start BGP 
#                   4. Get BGP Info
#                   5. Release resources
#
# DUT configuration:
#           none
#
# Topology
#                 STC Port1                            STC Port2                       
#               [BGP router 1]  -------------------   [BGP router 2]
#                        
#                                         
#
#################################

# Run sample:
#            c:\>python HLTAPI_BGP_LS.py 10.61.44.2 1/1 1/2

import sth
import time
from sys import argv
filename,device,port1,port2 = argv
port_list = [port1,port2]
port_handle = []


#Config the parameters for the logging
test_sta = sth.test_config (
    log                                              = '1',
    logfile                                          = 'bgp_ls_logfile',
    vendorlogfile                                    = 'bgp_ls_stcExport',
    vendorlog                                        = '1',
    hltlog                                           = '1',
    hltlogfile                                       = 'bgp_ls_hltExport',
    hlt2stcmappingfile                               = 'bgp_ls_hlt2StcMapping',
    hlt2stcmapping                                   = '1',
    log_level                                        = '7')

status = test_sta['status']
if  status == '0' :
    print "run sth.test_config failed"
    print test_sta
else:
    print "***** run sth.test_config successfully"


########################################
#Step1. Reserve and connect chassis ports
########################################

intStatus = sth.connect (
    device    = device,
    port_list = port_list);

status = intStatus['status']
i = 0
if  status == '1' :
    for port in port_list :
        port_handle.append(intStatus['port_handle'][device][port])
        print "\n reserved ports",port,":", port_handle[i],": port_handle[%s]" % i
        i += 1
else :
    print "\nFailed to retrieve port handle!\n"
    print port_handle

##############################################################
#config the parameters for optimization and parsing
##############################################################

test_ctrl_sta = sth.test_control (
        action                                           = 'enable');

status = test_ctrl_sta['status']
if (status == '0') :
    print("run sth.test_control failed")
    print(test_ctrl_sta)
else:
    print("***** run sth.test_control successfully")



##############################################################
# Step 2.Config BGP on Port1 & port2 with Link state NLRI
##############################################################

#start to create the device: Device 1
#configure BGP router1
device_ret0 = sth.emulation_bgp_config (
          mode                                             = 'enable',
          retries                                          = '100',
          vpls_version                                     = 'VERSION_00',
          routes_per_msg                                   = '2000',
          staggered_start_time                             = '100',
          update_interval                                  = '30',
          retry_time                                       = '30',
          staggered_start_enable                           = '1',
          md5_key_id                                       = '1',
          md5_key                                          = 'Spirent',
          md5_enable                                       = '0',
          link_ls_non_vpn_nlri                             = '1',
          ip_stack_version                                 = '4',
          port_handle                                      = port_handle[0],
          bgp_session_ip_addr                              = 'interface_ip',
          remote_ip_addr                                   = '193.85.1.3',
          ip_version                                       = '4',
          remote_as                                        = '1',
          hold_time                                        = '90',
          restart_time                                     = '90',
          route_refresh                                    = '0',
          local_as                                         = '1001',
          active_connect_enable                            = '1',
          stale_time                                       = '90',
          graceful_restart_enable                          = '0',
          local_router_id                                  = '192.0.0.3',
          next_hop_ip                                      = '193.85.1.3',
          local_ip_addr                                    = '193.85.1.1',
          netmask                                          = '24',
          mac_address_start                                = '00:10:94:00:00:01');

status = device_ret0['status']
if (status == '0') :
     print("run sth.emulation_bgp_config failed")
     print(device_ret0)
else:
     print("***** run sth.emulation_bgp_config successfully")

bgp_router1 = device_ret0['handle']
    
#configure BGP link state route of router 1
link_state_hnd = sth.emulation_bgp_route_config (
    mode                                                   = 'add',
    handle                                                 = bgp_router1,
    route_type                                             = 'link_state',
    ls_as_path                                             = '1',
    ls_as_path_segment_type                                = 'sequence',
    ls_enable_node                                         = 'true',
    ls_identifier                                          = '0',
    ls_identifiertype                                      = 'customized',
    ls_next_hop                                            = '1.0.0.1',
    ls_next_hop_type                                       = 'ipv4',
    ls_origin                                              = 'igp',
    ls_protocol_id                                         = 'OSPF_V2',
    ls_link_desc_flag                                      = 'as_number|bgp_ls_id|OSPF_AREA_ID|igp_router_id',
    ls_link_desc_as_num                                    = '1',
    ls_link_desc_bgp_ls_id                                 = '1666667',
    ls_link_desc_ospf_area_id                              = '0',
    ls_link_desc_igp_router_id_type                        = 'ospf_non_pseudo_node',
    ls_link_desc_igp_router_id                             = '1.0.0.1',
    ls_node_attr_flag                                      = 'SR_ALGORITHMS|SR_CAPS',
    ls_node_attr_sr_algorithms                             = 'LINK_METRIC_BASED_SPF',
    ls_node_attr_sr_value_type                             = 'label',
    ls_node_attr_sr_capability_flags                       = 'ipv4',
    ls_node_attr_sr_capability_base_list                   = '100',
    ls_node_attr_sr_capability_range_list                  = '100')

status = link_state_hnd['status']
if status == 0 :
    print "run sth.emulation_bgp_route_link_state failed"
    print link_state_hnd
else :
    print "run sth.emulation_bgp_route_link_state successfully++++++++++++++++++++++++++++"
    print link_state_hnd

lsLinkConfigHnd = link_state_hnd['handles']

#configure Link contents under BGP LS route

ls_link_hnd = sth.emulation_bgp_route_config (
    mode                                                   = 'add',
    handle                                                 = bgp_router1,
    route_handle                                           = lsLinkConfigHnd,
    route_type                                             = 'link_state',
    ls_link_attr_flag                                      = 'SR_ADJ_SID',
    ls_link_attr_link_protection_type                      = 'EXTRA_TRAFFIC',
    ls_link_attr_value                                     = '9001',
    ls_link_attr_value_type                                = 'label',
    ls_link_attr_weight                                    = '1',
    ls_link_attr_te_sub_tlv_type                           = 'local_ip|remote_ip',
    ls_link_desc_flags                                     = 'ipv4_intf_addr|IPV4_NBR_ADDR',
    ls_link_desc_ipv4_intf_addr                            = '1.0.0.1',
    ls_link_desc_ipv4_neighbor_addr                        = '1.0.0.2',
    ls_link_attr_te_local_ip                               = '1.0.0.1',
    ls_link_attr_te_remote_ip                              = '1.0.0.2')

status = ls_link_hnd['status']
if status == 0 :
    print "run sth.emulation_bgp_route_ls_link_hnd failed"
    print ls_link_hnd
else :
    print "run sth.emulation_bgp_route_ls_link_hnd successfully"
    print ls_link_hnd

#configure IPv4 Prefix under BGP LS route
ipv4_prefix_hnd = sth.emulation_bgp_route_config (
    mode                                                   = 'add',
    handle                                                 = bgp_router1,
    route_handle                                           = lsLinkConfigHnd,
    route_type                                             = 'link_state',
    ls_prefix_attr_flags                                   = 'PREFIX_METRIC|SR_PREFIX_SID',
    ls_prefix_attr_algorithm                               = '0',
    ls_prefix_attr_prefix_metric                           = '1',
    ls_prefix_attr_value                                   = '101',
    ls_prefix_desc_flags                                   = 'ip_reach_info|ospf_rt_type',
    ls_prefix_desc_ip_prefix_count                         = '1',
    ls_prefix_desc_ip_prefix_type                          = 'ipv4_prefix',
    ls_prefix_desc_ipv4_prefix                             = '1.0.0.0',
    ls_prefix_desc_ipv4_prefix_length                      = '24',
    ls_prefix_desc_ipv4_prefix_step                        = '1',
    ls_prefix_desc_ospf_route_type                         = 'intra_area')

status = ipv4_prefix_hnd['status']
if status == 0 :
    print "run sth.emulation_bgp_route_ipv4_prefix_hnd failed"
    print ipv4_prefix_hnd
else :
    print "run sth.emulation_bgp_route_ipv4_prefix_hnd successfully"
    print ipv4_prefix_hnd

#start to create the device: Device 2
#configure BGP router2
device_ret1 = sth.emulation_bgp_config (
          mode                                             = 'enable',
          retries                                          = '100',
          vpls_version                                     = 'VERSION_00',
          routes_per_msg                                   = '2000',
          staggered_start_time                             = '100',
          update_interval                                  = '30',
          retry_time                                       = '30',
          staggered_start_enable                           = '1',
          md5_key_id                                       = '1',
          md5_key                                          = 'Spirent',
          md5_enable                                       = '0',
          link_ls_non_vpn_nlri                             = '1',
          ip_stack_version                                 = '4',
          port_handle                                      = port_handle[1],
          bgp_session_ip_addr                              = 'interface_ip',
          remote_ip_addr                                   = '193.85.1.1',
          ip_version                                       = '4',
          view_routes                                      = '0',
          remote_as                                        = '1001',
          hold_time                                        = '90',
          restart_time                                     = '90',
          route_refresh                                    = '0',
          local_as                                         = '1',
          active_connect_enable                            = '1',
          stale_time                                       = '90',
          graceful_restart_enable                          = '0',
          local_router_id                                  = '192.0.0.3',
          next_hop_ip                                      = '193.85.1.1',
          local_ip_addr                                    = '193.85.1.3',
          netmask                                          = '24',
          mac_address_start                                = '00:10:94:00:00:03');

status = device_ret1['status']
if (status == '0') :
     print("run sth.emulation_bgp_config failed")
     print(device_ret1)
else:
     print("***** run sth.emulation_bgp_config successfully")

bgp_router2 = device_ret1['handle']
    
#configure BGP link state route of router 2
link_state_hnd = sth.emulation_bgp_route_config (
    mode                                                   = 'add',
    handle                                                 = bgp_router2,
    route_type                                             = 'link_state',
    ls_as_path                                             = '1',
    ls_as_path_segment_type                                = 'sequence',
    ls_enable_node                                         = 'true',
    ls_identifier                                          = '0',
    ls_identifiertype                                      = 'customized',
    ls_next_hop                                            = '1.0.0.2',
    ls_next_hop_type                                       = 'ipv4',
    ls_origin                                              = 'igp',
    ls_protocol_id                                         = 'OSPF_V2',
    ls_link_desc_flag                                      = 'as_number|bgp_ls_id|OSPF_AREA_ID|igp_router_id',
    ls_link_desc_as_num                                    = '1',
    ls_link_desc_bgp_ls_id                                 = '1666667',
    ls_link_desc_ospf_area_id                              = '0',
    ls_link_desc_igp_router_id_type                        = 'ospf_non_pseudo_node',
    ls_link_desc_igp_router_id                             = '1.0.0.2',
    ls_node_attr_flag                                      = 'SR_ALGORITHMS|SR_CAPS',
    ls_node_attr_sr_algorithms                             = 'LINK_METRIC_BASED_SPF',
    ls_node_attr_sr_value_type                             = 'label',
    ls_node_attr_sr_capability_flags                       = 'ipv4',
    ls_node_attr_sr_capability_base_list                   = '100',
    ls_node_attr_sr_capability_range_list                  = '100')

status = link_state_hnd['status']
if status == 0 :
    print "run sth.emulation_bgp_route_link_state failed"
    print link_state_hnd
else :
    print "run sth.emulation_bgp_route_link_state successfully"
    print link_state_hnd

lsLinkConfigHnd = link_state_hnd['handles']

#configure Link contents under BGP LS route

ls_link_hnd = sth.emulation_bgp_route_config (
    mode                                                   = 'add',
    handle                                                 = bgp_router2,
    route_handle                                           = lsLinkConfigHnd,
    route_type                                             = 'link_state',
    ls_link_attr_flag                                      = 'SR_ADJ_SID',
    ls_link_attr_link_protection_type                      = 'EXTRA_TRAFFIC',
    ls_link_attr_value                                     = '9001',
    ls_link_attr_value_type                                = 'label',
    ls_link_attr_weight                                    = '1',
    ls_link_attr_te_sub_tlv_type                           = 'local_ip|remote_ip',
    ls_link_desc_flags                                     = 'ipv4_intf_addr|IPV4_NBR_ADDR',
    ls_link_desc_ipv4_intf_addr                            = '1.0.0.1',
    ls_link_desc_ipv4_neighbor_addr                        = '1.0.0.2',
    ls_link_attr_te_local_ip                               = '1.0.0.1',
    ls_link_attr_te_remote_ip                              = '1.0.0.2')

status = ls_link_hnd['status']
if status == 0 :
    print "run sth.emulation_bgp_route_ls_link_hnd failed"
    print ls_link_hnd
else :
    print "run sth.emulation_bgp_route_ls_link_hnd successfully"
    print ls_link_hnd

#configure IPv4 Prefix under BGP LS route
ipv4_prefix_hnd = sth.emulation_bgp_route_config (
    mode                                                   = 'add',
    handle                                                 = bgp_router2,
    route_handle                                           = lsLinkConfigHnd,
    route_type                                             = 'link_state',
    ls_prefix_attr_flags                                   = 'PREFIX_METRIC|SR_PREFIX_SID',
    ls_prefix_attr_algorithm                               = '0',
    ls_prefix_attr_prefix_metric                           = '1',
    ls_prefix_attr_value                                   = '101',
    ls_prefix_desc_flags                                   = 'ip_reach_info|ospf_rt_type',
    ls_prefix_desc_ip_prefix_count                         = '1',
    ls_prefix_desc_ip_prefix_type                          = 'ipv4_prefix',
    ls_prefix_desc_ipv4_prefix                             = '1.0.0.0',
    ls_prefix_desc_ipv4_prefix_length                      = '24',
    ls_prefix_desc_ipv4_prefix_step                        = '1',
    ls_prefix_desc_ospf_route_type                         = 'intra_area')

status = ipv4_prefix_hnd['status']
if status == 0 :
    print "run sth.emulation_bgp_route_ipv4_prefix_hnd failed"
    print ipv4_prefix_hnd
else :
    print "run sth.emulation_bgp_route_ipv4_prefix_hnd successfully"
    print ipv4_prefix_hnd
     
     
     
     
     
     
#config part is finished
sth.invoke ('stc::perform saveasxml -filename bgp_ls_py.xml')


##############################################################
# Step 3.start BGP
##############################################################

device_list = [device_ret0['handle'],device_ret1['handle']]

ctrl_ret1 = sth.emulation_bgp_control (
          handle                                           = device_list,
          mode                                             = 'start');

status = ctrl_ret1['status']
if (status == '0') :
     print("run sth.emulation_bgp_control failed")
     print(ctrl_ret1)
else:
     print("***** run sth.emulation_bgp_control successfully")

time.sleep (5)
##############################################################
# Step 4. Get BGP Info
##############################################################

device = device_ret0['handle'].split()[0]

results_ret1 = sth.emulation_bgp_info (
          handle                                           = device,
          mode                                             = 'stats');

status = results_ret1['status']
if (status == '0') :
     print("run sth.emulation_bgp_info failed")
     print(results_ret1)
else:
     print("***** run sth.emulation_bgp_info successfully, and results is:")
     print(results_ret1)

device = device_ret1['handle'].split()[0]

results_ret2 = sth.emulation_bgp_info (
          handle                                           = device,
          mode                                             = 'stats');

status = results_ret2['status']
if (status == '0') :
     print("run sth.emulation_bgp_info failed")
     print(results_ret2)
else:
     print("***** run sth.emulation_bgp_info successfully, and results is:")
     print(results_ret2)


##############################################################
# Step 5. Release resources
##############################################################

cleanup_sta = sth.cleanup_session (
          port_handle                                      = [port_handle[0],port_handle[1]],
          clean_dbfile                                     = '1');

status = cleanup_sta['status']
if (status == '0') :
     print("run sth.cleanup_session failed")
     print(cleanup_sta)
else:
     print("***** run sth.cleanup_session successfully")


print("**************Finish***************")
