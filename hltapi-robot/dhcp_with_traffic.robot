#########################################################################################################################
#
# File Name:           dhcp_with_traffic.robot                 
# Description:         This HLTAPI robot script demonstrates the procedure to setup DHCP server/client 
#                      and start DHCP server/client and then get stats.
#
# Main Steps:          Step 1: Connect to chassis and reserve ports                                
#                      Step 2: Create DHCP server and DHCP client on port2 and port1
#                      Step 3: Start DHCP server and Bind DHCP device on DHCP client
#                      Step 4: View DHCP info
#                      Step 5: Create a host block on port2
#                      Step 6: Create two streamblocks on port1 and port2
#                      Step 7: Start traffic and stop traffic
#                      Step 8: Get traffic result
#                      Step 9: Cleanup sessions and release ports
#
#                                                                       
# Topology:
#                      STC Port2                      STC Port1                       
#                     [DHCP Server]------------------[DHCP clients]
#                                                                    
#  
#
# Run sample:
#            c:\>robot dhcp_with_traffic.robot     
#                                                                   


*** Settings ***
Documentation  Get libraries
Library           BuiltIn
Library           Collections
Library           sth.py
Library           String

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
dhcp with traffic test

##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=dhcp_with_traffic_logfile   vendorlogfile=dhcp_with_traffic_stcExport   vendorlog=1   hltlog=1   hltlogfile=dhcp_with_traffic_hltExport   hlt2stcmappingfile=dhcp_with_traffic_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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

##############################################################
#Step 1: Connect to chassis and reserve ports
##############################################################

    Set Test Variable  ${port_index}  1

    ${device} =  Set Variable  10.61.47.130

    @{port_list} =  Create List  1/1  1/2

    ${intStatus} =  connect  device=${device}  port_list=${port_list}  break_locks=1  offline=0

    ${status} =  Get From Dictionary  ${intStatus}  status
    log to console  \n *****************the return of connect device are: ${intStatus}
    Run Keyword If  ${status} == 1  Get Port Handle  ${intStatus}  ${device}  @{port_list}
    ...  ELSE  log to console  \n<error> Failed to retrieve port handle! Error message: ${intStatus}

##############################################################
#get the device info
##############################################################

    ${device_info} =  device info  ports=1  port_handle=${port1} ${port2}   fspec_version=1

    ${status} =  Get From Dictionary  ${device_info}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun device info failed\n${device_info}
    ...  ELSE  Log To Console  \n***** run device info successfully\n${device_info}.

##############################################################
#interface config
##############################################################

    ${int_ret0} =  interface config  mode=config   port_handle=${port1}   create_host=false   intf_mode=ethernet    scheduling_mode=RATE_BASED   port_loadunit=PERCENT_LINE_RATE   port_load=10   enable_ping_response=0   control_plane_mtu=1500   pfc_negotiate_by_dcbx=0   speed=ether10000   duplex=full   autonegotiation=1   alternate_speeds=0


    ${status} =  Get From Dictionary  ${int_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun interface config failed\n${int_ret0}
    ...  ELSE  Log To Console  \n***** run interface config successfully

    ${int_ret1} =  interface config  mode=config   port_handle=${port2}   create_host=false   intf_mode=ethernet   scheduling_mode=RATE_BASED   port_loadunit=PERCENT_LINE_RATE   port_load=10   enable_ping_response=0   control_plane_mtu=1500   pfc_negotiate_by_dcbx=0   speed=ether10000   duplex=full   autonegotiation=1   alternate_speeds=0

    ${status} =  Get From Dictionary  ${int_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun interface config failed\n${int_ret1}
    ...  ELSE  Log To Console  \n***** run interface config successfully

    
##############################################################
#Step 2: Create DHCP server and DHCP client on port2 and port1
##############################################################

#start to create DHCP server on port2: 

    ${device_ret0} =  emulation dhcp server config  mode=create   ip_version=4   encapsulation=ETHERNET_II   remote_id=remoteId_@p-@b-@s   ipaddress_count=245   ipaddress_pool=10.1.1.10   vpn_id_count=1   vpn_id_type=nvt_ascii   circuit_id_count=1   remote_id_count=1   circuit_id=circuitId_@p   vpn_id=spirent_@p   ipaddress_increment=1   port_handle=${port2}   lease_time=3600   tos_value=192   offer_reserve_time=10   min_allowed_lease_time=600   assign_strategy=GATEWAY   host_name=server_@p-@b-@s   renewal_time_percent=50   enable_overlap_addr=false   decline_reserve_time=10   rebinding_time_percent=87.5   ip_repeat=0   remote_mac=00:00:01:00:00:01   ip_address=10.1.1.2   ip_prefix_length=24   ip_gateway=10.1.1.1   ip_step=0.0.0.1   local_mac=00:10:94:00:00:02   count=1


    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp server config failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run emulation dhcp server config successfully

#start to create DHCP client on port1:

    ${device_ret1port} =  emulation dhcp config  mode=create   ip_version=4   port_handle=${port1}   starting_xid=0   lease_time=60   outstanding_session_count=1000   request_rate=100   msg_timeout=60000   retry_count=4   sequencetype=SEQUENTIAL   max_dhcp_msg_size=576   release_rate=100

    ${status} =  Get From Dictionary  ${device_ret1port}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp config failed\n${device_ret1port}
    ...  ELSE  Log To Console  \n***** run emulation dhcp config successfully

    ${dhcp_handle} =  Get From Dictionary  ${device_ret1port}  handles
    
#start to create DHCP group on DHCP client: 
    ${device_ret1} =  emulation dhcp group config  mode=create   dhcp_range_ip_type=4   encap=ethernet_ii   gateway_addresses=1   handle=${dhcp_handle}   host_name=client_@p-@b-@s   enable_arp_server_id=false   broadcast_bit_flag=1   opt_list=1 6 15 33 44   enable_router_option=false   gateway_ipv4_addr_step=0.0.0.0   ipv4_gateway_address=192.85.2.1   mac_addr=00:10:94:00:00:01   mac_addr_step=00:00:00:00:00:01   num_sessions=10

    ${status} =  Get From Dictionary  ${device_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp group config failed\n${device_ret1}
    ...  ELSE  Log To Console  \n***** run emulation dhcp group config successfully

#config part is finished

####################
#Start to capture
####################
    Log To Console  \nStart to capture

    ${packet_control} =  packet control  port_handle=all  action=start

    ${status} =  Get From Dictionary  ${packet_control}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun packet control failed\n${packet_control}
    ...  ELSE  Log To Console  \n***** run packet control successfully
    
##################################################################################
#Step 3: Start DHCP server on port2 and Bind DHCP device on DHCP client on port1
##################################################################################
    
#start DHCP server on port2: 

    ${ctrl_ret1} =  emulation dhcp server control  port_handle=${port2}   action=connect   ip_version=4

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp server control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation dhcp server control successfully

#start to start DHCP client on port1: 

    ${ctrl_ret2} =  emulation dhcp control  port_handle=${port1}   action=bind   ip_version=4

    ${status} =  Get From Dictionary  ${ctrl_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp control failed\n${ctrl_ret2}
    ...  ELSE  Log To Console  \n***** run emulation dhcp control successfully

    Sleep  3s
    
###########################
#Step 4: View DHCP info
###########################
    
#start to get DHCP server stats

    ${results_ret1} =  emulation dhcp server stats  port_handle=${port2}   action=COLLECT   ip_version=4

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp server stats failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run emulation dhcp server stats successfully, and results is:\n${results_ret1}
    
#start to get DHCP client stats

    ${results_ret2} =  emulation dhcp stats  port_handle=${port1}   action=collect   mode=detailed_session   ip_version=4

    ${status} =  Get From Dictionary  ${results_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp stats failed\n${results_ret2}
    ...  ELSE  Log To Console  \n***** run emulation dhcp stats successfully, and results is:\n${results_ret2}

    ${ip} =  evaluate  ${results_ret2}['group']['dhcpv4blockconfig1']['1']['ipv4_addr']

    Log To Console  \nDHCP client IP is : ${ip}

##########################################
#Step 5: Create a host block on port2
##########################################

    ${hostblock} =  emulation device config  mode=create  port_handle=${port2}  intf_ip_addr=10.1.1.200  count=10  gateway_ip_addr=10.1.1.254

    ${status} =  Get From Dictionary  ${hostblock}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation device config failed\n${hostblock}
    ...  ELSE  Log To Console  \n***** run emulation device config successfully, and return is:\n${hostblock}

##############################################################
#Step 6: Create two streamblocks on port1 and port2
##############################################################

#get host handle from hostblock and DHCP_group_config
    
    ${hd1} =  Get From Dictionary  ${device_ret1}  handle
    ${hd2} =  Get From Dictionary  ${hostblock}  handle

    ${streamblock} =  traffic config  mode=create  port_handle=${port1}  port_handle2=${port2}  emulation_src_handle=${hd1}
    ...  emulation_dst_handle=${hd2}  bidirectional=1

    ${status} =  Get From Dictionary  ${streamblock}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock}
    ...  ELSE  Log To Console  \n***** run traffic config successfully, and return is:\n${streamblock}

##############################################################
#Step 7: Start traffic and stop traffic
##############################################################

    ${traffic_ctrl_ret} =  traffic control  port_handle=all   action=run

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

    ${traffic_ctrl_ret} =  traffic control  port_handle=all   action=stop

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

##############################
#Stop capture and save packets
##############################
    Log To Console  \nStop capture and save packets

    ${packet_stats1} =  packet stats  port_handle=${port1}  action=filtered  stop=1  format=pcap  filename=port1.pcap

    ${packet_stats2} =  packet stats  port_handle=${port2}  action=filtered  stop=1  format=pcap  filename=port2.pcap

    ${status} =  Get From Dictionary  ${packet_stats1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun packet control failed\n${packet_stats1}
    ...  ELSE  Log To Console  \n***** run packet control successfully

    ${status} =  Get From Dictionary  ${packet_stats2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun packet control failed\n${packet_stats2}
    ...  ELSE  Log To Console  \n***** run packet control successfully

##############################################################
#Step 8: Get traffic result
##############################################################

    Log To Console  \nGet traffic statistics

    ${traffic_results_ret} =  traffic stats  port_handle=${port1} ${port2}   mode=aggregate

    ${status} =  Get From Dictionary  ${traffic_results_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic stats failed\n${traffic_results_ret}
    ...  ELSE  Log To Console  \n***** run traffic stats successfully, and results is:\n${traffic_results_ret}

##############################################################
#Step 9: Cleanup sessions and release ports
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    Log To Console  \n**************Finish***************

