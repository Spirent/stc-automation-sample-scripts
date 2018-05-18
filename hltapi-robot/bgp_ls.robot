#################################
#
# File Name:         bgp_ls.robot
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
#################################

# Run sample:
#            c:\>robot bgp_ls.robot

*** Settings ***
Documentation  Get libraries
Library           BuiltIn
Library           Collections
Library           sth.py

*** Variables ***

*** Keywords ***
Get Port Handle
    [Arguments]  ${dict}  ${chassis}  @{port_list}
    ${port} =  Set Variable  ${EMPTY}
    :FOR  ${port}  IN  @{port_list}
    \  ${Rstatus} =  Get From Dictionary  ${dict}  port_handle
    \  ${Rstatus} =  Get From Dictionary  ${Rstatus}  ${chassis}
    \  ${Rstatus} =  Get From Dictionary  ${Rstatus}  ${port}
    \  Set Test Variable    ${port${port_index}}    ${Rstatus}
    \  Log To Console  \nreserved ports: ${chassis} ${port} ${Rstatus}
    \  ${port_index}    Evaluate    ${port_index}+1
    \  Set Test Variable  ${port_index}  ${port_index}

*** Test Cases ***
BGP-LS Test

##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=bgp_ls_py_logfile   vendorlogfile=bgp_ls_py_stcExport   vendorlog=1   hltlog=1   hltlogfile=bgp_ls_py_hltExport   hlt2stcmappingfile=bgp_ls_py_hlt2StcMapping   hlt2stcmapping=1   log_level=7

    ${status} =  Get From Dictionary  ${test_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test config failed\n${test_sta}
    ...  ELSE  Log To Console  \n***** run test config successfully

##############################################################
#config the parameters for optimization and parsing
##############################################################

    ${test_ctrl_sta} =  test control  action=enable

    ${status} =  Get From Dictionary  ${test_ctrl_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test control failed\n${test_ctrl_sta}
    ...  ELSE  Log To Console  \n***** run test control successfully

############################################
# Step1. Reserve and connect chassis ports
############################################

    Set Test Variable  ${port_index}  1
    ${device} =  Set Variable  10.61.47.130
    @{port_list} =  Create List  1/1  1/2
    ${intStatus} =  connect  device=${device}  port_list=${port_list}  break_locks=1  offline=0
    ${status} =  Get From Dictionary  ${intStatus}  status
    Run Keyword If  ${status} == 1  Get Port Handle  ${intStatus}  ${device}  @{port_list}
    ...  ELSE  log to console  \n<error> Failed to retrieve port handle! Error message: ${intStatus}
    
###########################
#get the device info
###########################

    ${device_info} =  device info  ports=1  port_handle=${port1} ${port2}   fspec_version=1

    ${status} =  Get From Dictionary  ${device_info}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun device info failed\n${device_info}
    ...  ELSE  Log To Console  \n***** run device info successfully

##############################################################
# Step 2.Config BGP on Port1 & port2 with Link state NLRI
##############################################################

#start to create the device: Device 1
#configure BGP router1

    ${device_ret0} =  emulation bgp config  mode=enable   retries=100   vpls_version=VERSION_00   routes_per_msg=2000   staggered_start_time=100   update_interval=30   retry_time=30   staggered_start_enable=1   md5_key_id=1   md5_key=Spirent   md5_enable=0   link_ls_non_vpn_nlri=1   ip_stack_version=4   port_handle=${port1}   bgp_session_ip_addr=interface_ip   remote_ip_addr=193.85.1.3   ip_version=4   view_routes=0   remote_as=1   hold_time=90   restart_time=90   route_refresh=0   local_as=1001   active_connect_enable=1   stale_time=90   graceful_restart_enable=0   local_router_id=192.0.0.3   next_hop_ip=193.85.1.3   local_ip_addr=193.85.1.1   netmask=24   mac_address_start=00:10:94:00:00:01

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation bgp config failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run emulation bgp config successfully

    ${bgp_router1} =  Get From Dictionary  ${device_ret0}  handle

#configure BGP link state route of router 1
    ${device_ret0_route1} =  emulation bgp route config  handle=${bgp_router1}   mode=add   route_type=link_state   ls_as_path=1   ls_as_path_segment_type=sequence   ls_enable_node=true   ls_identifier=0   ls_identifiertype=customized   ls_next_hop=1.0.0.1
    ...  ls_next_hop_type=ipv4   ls_origin=igp   ls_protocol_id=OSPF_V2   ls_link_desc_flag=as_number|bgp_ls_id|OSPF_AREA_ID|igp_router_id
    ...  ls_link_desc_as_num=1   ls_link_desc_bgp_ls_id=1666667   ls_link_desc_ospf_area_id=0   ls_link_desc_igp_router_id_type=ospf_non_pseudo_node
    ...  ls_link_desc_igp_router_id=1.0.0.1   ls_node_attr_flag=SR_ALGORITHMS|SR_CAPS   ls_node_attr_sr_algorithms=LINK_METRIC_BASED_SPF
    ...  ls_node_attr_sr_value_type=label   ls_node_attr_sr_capability_flags=ipv4   ls_node_attr_sr_capability_base_list=100
    ...  ls_node_attr_sr_capability_range_list=100

    ${status} =  Get From Dictionary  ${device_ret0_route1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun sth.emulation_bgp_route_link_state failed\n${device_ret0_route1}
    ...  ELSE  Log To Console  \n***** run sth.emulation_bgp_route_link_state successfully

    ${lsLinkConfigHnd} =  Get From Dictionary  ${device_ret0_route1}  handles

#configure Link contents under BGP LS route

    ${device_ret0_route1} =  emulation bgp route config  handle=${bgp_router1}   route_handle=${lsLinkConfigHnd}   mode=add   route_type=link_state
    ...  ls_link_attr_flag=SR_ADJ_SID   ls_link_attr_link_protection_type=EXTRA_TRAFFIC   ls_link_attr_value=9001   ls_link_attr_value_type=label
    ...  ls_link_attr_weight=1   ls_link_attr_te_sub_tlv_type=local_ip|remote_ip   ls_link_desc_flags=ipv4_intf_addr|IPV4_NBR_ADDR   
    ...  ls_link_desc_ipv4_intf_addr=1.0.0.1   ls_link_desc_ipv4_neighbor_addr=1.0.0.2   ls_link_attr_te_local_ip=1.0.0.1 
    ...  ls_link_attr_te_remote_ip=1.0.0.2

    ${status} =  Get From Dictionary  ${device_ret0_route1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun sth.emulation_bgp_route_ls_link_hnd failed\n${device_ret0_route1}
    ...  ELSE  Log To Console  \n***** run sth.emulation_bgp_route_ls_link_hnd successfully

#configure IPv4 Prefix under BGP LS route

    ${device_ret0_route1} =  emulation bgp route config  handle=${bgp_router1}   route_handle=${lsLinkConfigHnd}   mode=add   route_type=link_state
    ...  ls_prefix_attr_flags=PREFIX_METRIC|SR_PREFIX_SID   ls_prefix_attr_algorithm=0   ls_prefix_attr_prefix_metric=1   ls_prefix_attr_value=101
    ...  ls_prefix_desc_flags=ip_reach_info|ospf_rt_type   ls_prefix_desc_ip_prefix_count=1   ls_prefix_desc_ip_prefix_type=ipv4_prefix
    ...  ls_prefix_desc_ipv4_prefix=1.0.0.0   ls_prefix_desc_ipv4_prefix_length=24   ls_prefix_desc_ipv4_prefix_step=1
    ...  ls_prefix_desc_ospf_route_type=intra_area

    ${status} =  Get From Dictionary  ${device_ret0_route1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun sth.emulation_bgp_route_ipv4_prefix_hnd failed\n${device_ret0_route1}
    ...  ELSE  Log To Console  \n***** run sth.emulation_bgp_route_ipv4_prefix_hnd successfully

#start to create the device: Device 2
#configure BGP router2

    ${device_ret1} =  emulation bgp config  mode=enable   retries=100   vpls_version=VERSION_00   routes_per_msg=2000   staggered_start_time=100   update_interval=30   retry_time=30   staggered_start_enable=1   md5_key_id=1   md5_key=Spirent   md5_enable=0   link_ls_non_vpn_nlri=1   ip_stack_version=4   port_handle=${port2}   bgp_session_ip_addr=interface_ip   remote_ip_addr=193.85.1.1   ip_version=4   view_routes=0   remote_as=1001   hold_time=90   restart_time=90   route_refresh=0   local_as=1   active_connect_enable=1   stale_time=90   graceful_restart_enable=0   local_router_id=192.0.0.3   next_hop_ip=193.85.1.1   local_ip_addr=193.85.1.3   netmask=24   mac_address_start=00:10:94:00:00:03

    ${status} =  Get From Dictionary  ${device_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation bgp config failed\n${device_ret1}
    ...  ELSE  Log To Console  \n***** run emulation bgp config successfully

    ${bgp_router2} =  Get From Dictionary  ${device_ret1}  handle

#configure BGP link state route of router 2

    ${device_ret0_route1} =  emulation bgp route config  handle=${bgp_router2}   mode=add   route_type=link_state   ls_as_path=1   ls_as_path_segment_type=sequence   ls_enable_node=true   ls_identifier=0   ls_identifiertype=customized   ls_next_hop=1.0.0.2
    ...  ls_next_hop_type=ipv4   ls_origin=igp   ls_protocol_id=OSPF_V2   ls_link_desc_flag=as_number|bgp_ls_id|OSPF_AREA_ID|igp_router_id
    ...  ls_link_desc_as_num=1   ls_link_desc_bgp_ls_id=1666667   ls_link_desc_ospf_area_id=0   ls_link_desc_igp_router_id_type=ospf_non_pseudo_node
    ...  ls_link_desc_igp_router_id=1.0.0.2   ls_node_attr_flag=SR_ALGORITHMS|SR_CAPS   ls_node_attr_sr_algorithms=LINK_METRIC_BASED_SPF
    ...  ls_node_attr_sr_value_type=label   ls_node_attr_sr_capability_flags=ipv4   ls_node_attr_sr_capability_base_list=100
    ...  ls_node_attr_sr_capability_range_list=100

    ${status} =  Get From Dictionary  ${device_ret0_route1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun sth.emulation_bgp_route_link_state failed\n${device_ret0_route1}
    ...  ELSE  Log To Console  \n***** run sth.emulation_bgp_route_link_state successfully

    ${lsLinkConfigHnd} =  Get From Dictionary  ${device_ret0_route1}  handles

#configure Link contents under BGP LS route

    ${device_ret0_route1} =  emulation bgp route config  handle=${bgp_router2}   route_handle=${lsLinkConfigHnd}   mode=add   route_type=link_state
    ...  ls_link_attr_flag=SR_ADJ_SID   ls_link_attr_link_protection_type=EXTRA_TRAFFIC   ls_link_attr_value=9001   ls_link_attr_value_type=label
    ...  ls_link_attr_weight=1   ls_link_attr_te_sub_tlv_type=local_ip|remote_ip   ls_link_desc_flags=ipv4_intf_addr|IPV4_NBR_ADDR   
    ...  ls_link_desc_ipv4_intf_addr=1.0.0.1   ls_link_desc_ipv4_neighbor_addr=1.0.0.2   ls_link_attr_te_local_ip=1.0.0.1 
    ...  ls_link_attr_te_remote_ip=1.0.0.2

    ${status} =  Get From Dictionary  ${device_ret0_route1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun run sth.emulation_bgp_route_ls_link_hnd failed\n${device_ret0_route1}
    ...  ELSE  Log To Console  \n***** run run sth.emulation_bgp_route_ls_link_hnd successfully

#configure IPv4 Prefix under BGP LS route

    ${device_ret0_route1} =  emulation bgp route config  handle=${bgp_router2}   route_handle=${lsLinkConfigHnd}   mode=add   route_type=link_state
    ...  ls_prefix_attr_flags=PREFIX_METRIC|SR_PREFIX_SID   ls_prefix_attr_algorithm=0   ls_prefix_attr_prefix_metric=1   ls_prefix_attr_value=101
    ...  ls_prefix_desc_flags =ip_reach_info|ospf_rt_type   ls_prefix_desc_ip_prefix_count=1   ls_prefix_desc_ip_prefix_type=ipv4_prefix
    ...  ls_prefix_desc_ipv4_prefix=1.0.0.0   ls_prefix_desc_ipv4_prefix_length=24   ls_prefix_desc_ipv4_prefix_step=1
    ...  ls_prefix_desc_ospf_route_type=intra_area

    ${status} =  Get From Dictionary  ${device_ret0_route1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun sth.emulation_bgp_route_ipv4_prefix_hnd failed\n${device_ret0_route1}
    ...  ELSE  Log To Console  \n***** run sth.emulation_bgp_route_ipv4_prefix_hnd successfully\n${device_ret0_route1}

#config part is finished
    
##############################################################
# Step 3.start BGP
##############################################################

    ${ctrl_ret1} =  emulation bgp control  handle=${bgp_router1} ${bgp_router2}    mode=start

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation bgp control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation bgp control successfully

    Sleep  5s

##############################################################
# Step 4. Get BGP Info
##############################################################   
    
    ${results_ret1} =  emulation bgp info  handle=${bgp_router1}   mode=stats

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation bgp info failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run emulation bgp info successfully, and results is:\n${results_ret1}

    ${results_ret2} =  emulation bgp info  handle=${bgp_router2}   mode=stats

    ${status} =  Get From Dictionary  ${results_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation bgp info failed\n${results_ret2}
    ...  ELSE  Log To Console  \n***** run emulation bgp info successfully, and results is:\n${results_ret2}

##############################################################
# Step 5. Release resources
##############################################################    

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

