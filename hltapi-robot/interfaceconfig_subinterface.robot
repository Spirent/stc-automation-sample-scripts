################################################################################
#
# File Name:                 interfaceconfig_subinterface.robot
#
# Description:   Allow interface_config to config subinterfaces. The following options have been added:
#           vlan
#           vlan_id
#           vlan_cfi
#           vlan_id_count
#           vlan_id_step
#           vlan_user_priority
#           qinq_incr_mode
#           vlan_outer_id
#           vlan_outer_cfi
#           vlan_outer_count
#           vlan_outer_id_step
#           vlan_outer_user_priority
#           gateway_step
#           ipv6_gateway_step
#           intf_ip_addr_step
#           ipv6_intf_addr_step
#           src_mac_addr_step
#
# Test steps:               
#                        1. Reserve and connect chassis ports
#                        2. Configure interface on two ports
#                        3. Configure streamblock on two ports
#                        4. Start capture
#                        5. Start traffic
#                        6. Stop traffic
#                        7. Stop and save capture
#                        8. Get traffic statistics
#                        9. Release resources
#
# Topology:
#                 10.21.0.2                   10.21.0.1
#                 10.22.0.2                   10.22.0.1
#                (STC Port1) -------------------(DUT) 11.55.0.1------------11.55.0.2 (STC Port2)
#                 10.23.0.2                   10.23.0.1
#                 10.24.0.2                   10.24.0.1
#
#
################################################################################
# 
# Run sample:
#            c:\>robot interfaceconfig_subinterface.robot


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
subinterface test

##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=interfaceconfig_subinterface_logfile   vendorlogfile=interfaceconfig_subinterface_stcExport   vendorlog=1   hltlog=1   hltlogfile=interfaceconfig_subinterface_hltExport   hlt2stcmappingfile=interfaceconfig_subinterface_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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

########################################
# Step1. Reserve and connect chassis ports
########################################

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
#Step2. Configure interface on two ports
##############################################################

    ${int_ret0} =  interface config  mode=config   port_handle=${port1}   create_host=false   intf_mode=ethernet   phy_mode=fiber   scheduling_mode=RATE_BASED   port_loadunit=PERCENT_LINE_RATE   port_load=10   intf_ip_addr=10.21.0.2   resolve_gateway_mac=true   gateway_step=0.1.0.0   gateway=10.21.0.1   dst_mac_addr=00:00:01:00:00:01   intf_ip_addr_step=0.1.0.0   netmask=255.255.255.255   enable_ping_response=0   control_plane_mtu=1500   flow_control=false   speed=ether1000   data_path_mode=normal   autonegotiation=1

    ${status} =  Get From Dictionary  ${int_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun interface config failed\n${int_ret0}
    ...  ELSE  Log To Console  \n***** run interface config successfully

    ${int_ret1} =  interface config  mode=config   port_handle=${port2}   create_host=false   intf_mode=ethernet   phy_mode=fiber   scheduling_mode=RATE_BASED   port_loadunit=PERCENT_LINE_RATE   port_load=10   intf_ip_addr=11.55.0.2   resolve_gateway_mac=true   gateway_step=0.0.0.0   gateway=11.55.0.1   dst_mac_addr=00:00:01:00:00:01   intf_ip_addr_step=0.1.0.0   netmask=255.255.255.255   enable_ping_response=0   control_plane_mtu=1500   flow_control=false   speed=ether1000   data_path_mode=normal   autonegotiation=1

    ${status} =  Get From Dictionary  ${int_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun interface config failed\n${int_ret1}
    ...  ELSE  Log To Console  \n***** run interface config successfully

##############################################################
#Step3. Configure streamblock on two ports
##############################################################

    ${streamblock_ret1} =  traffic config  mode=create   port_handle=${port1}   l2_encap=ethernet_ii_vlan   l3_protocol=ipv4   ip_id=0   ip_src_addr=10.21.0.2   ip_dst_addr=11.55.0.2   ip_ttl=255   ip_hdr_length=5   ip_protocol=253   ip_fragment_offset=0   ip_mbz=0   ip_precedence=0   ip_tos_field=0   vlan_id_repeat=0   vlan_id_mode=increment   vlan_id_count=4   vlan_id_step=01   mac_discovery_gw_count=4   inner_ip_gw_step=0.1.0.0   inner_ip_gw_count=4   mac_discovery_gw_step=0.1.0.0   ip_src_repeat_count=0   ip_src_count=4   ip_src_step=0.1.0.0   ip_src_mode=increment   ip_dst_count=2   ip_dst_repeat_count=0   ip_dst_step=0.0.0.1   ip_dst_mode=increment   mac_src=00:10:94:00:00:02   mac_dst=00:00:01:00:00:01   vlan_cfi=0   vlan_tpid=33024   vlan_id=4   vlan_user_priority=0   enable_control_plane=0   l3_length=108   name=StreamBlock_1   fill_type=constant   fcs_error=0   fill_value=0   frame_size=130   traffic_state=1   high_speed_result_analysis=1   length_mode=fixed   tx_port_sending_traffic_to_self_en=false   disable_signature=0   enable_stream_only_gen=1   endpoint_map=one_to_one   pkts_per_burst=1   inter_stream_gap_unit=bytes   burst_loop_count=30   transmit_mode=continuous   inter_stream_gap=12   rate_percent=10   mac_discovery_gw=10.21.0.1   enable_stream=true

    ${status} =  Get From Dictionary  ${streamblock_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock_ret1}
    ...  ELSE  Log To Console  \n***** run traffic config successfully

    ${streamblock_ret2} =  traffic config  mode=create   port_handle=${port2}   l2_encap=ethernet_ii   l3_protocol=ipv4   ip_id=0   ip_src_addr=11.55.0.2   ip_dst_addr=10.21.0.2   ip_ttl=255   ip_hdr_length=5   ip_protocol=253   ip_fragment_offset=0   ip_mbz=0   ip_precedence=0   ip_tos_field=0   ip_src_repeat_count=0   ip_src_count=2   ip_src_step=0.0.0.1   ip_src_mode=increment   ip_dst_count=4   ip_dst_repeat_count=0   ip_dst_step=0.0.0.1   ip_dst_mode=increment   mac_src=00:10:94:00:00:02   mac_dst=00:00:01:00:00:01   enable_control_plane=0   l3_length=108   name=StreamBlock_2   fill_type=constant   fcs_error=0   fill_value=0   frame_size=126   traffic_state=1   high_speed_result_analysis=1   length_mode=fixed   tx_port_sending_traffic_to_self_en=false   disable_signature=0   enable_stream_only_gen=1   endpoint_map=one_to_one   pkts_per_burst=1   inter_stream_gap_unit=bytes   burst_loop_count=30   transmit_mode=continuous   inter_stream_gap=12   rate_pps=1000   mac_discovery_gw=11.55.0.1   enable_stream=true

    ${status} =  Get From Dictionary  ${streamblock_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock_ret2}
    ...  ELSE  Log To Console  \n***** run traffic config successfully

#config part is finished
    
##############################################################
# Step4. Start capture
##############################################################
  
    ${packet_control} =  packet control  port_handle=all  action=start  

##############################################################
# Step5. Start traffic
##############################################################

    ${traffic_ctrl_ret} =  traffic control  port_handle=${port1} ${port2}   action=run

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

    Sleep  5s

##############################################################
# Step6. Stop traffic
##############################################################

    ${traffic_ctrl_ret} =  traffic control  port_handle=${port1} ${port2}   action=stop

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

##############################################################
# Step7. Stop and save capture
##############################################################

    ${packet_stats1} =  packet stats  port_handle=${port1}  action=filtered  stop=1  format=pcap  filename=sub_port1.pcap

    ${packet_stats2} =  packet stats  port_handle=${port2}  action=filtered  stop=1  format=pcap  filename=sub_port2.pcap

##############################################################
# Step8. Get traffic statistics
##############################################################
    
    Log To Console  Get traffic statistics of port2

    ${port2_stats} =  interface stats  port_handle=${port2}

    ${status} =  Get From Dictionary  ${port2_stats}  status
    Run Keyword If  ${status} == 0  Log To Console  \nGet interface stats failed\n${port2_stats}
    ...  ELSE  Log To Console  \n***** Get interface stats successfully , and results is:\n${port2_stats}

    Log To Console  Get traffic statistics of port1

    ${port1_stats} =  interface stats  port_handle=${port1}

    ${status} =  Get From Dictionary  ${port1_stats}  status
    Run Keyword If  ${status} == 0  Log To Console  \nGet interface stats failed\n${port1_stats}
    ...  ELSE  Log To Console  \n***** Get interface stats successfully , and results is:\n${port1_stats}   

##############################################################
# Step9. Release resources
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

