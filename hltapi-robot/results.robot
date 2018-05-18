#########################################################################################################################
#
# File Name:           results.robot                
# Description:         This HLTAPI robot script demonstrates the procedure of get DRV(Dynamic Result View) results
#                      and realtime results in DHCP scenario.
#                      
# Test Steps:          
#                      1. Reserve and connect chassis ports
#                      2. Create DHCP server and DHCP client on port2 and port1
#                      3. Start DHCP server and Bind DHCP device on DHCP client
#                      4. View DHCP info
#                      5. Create a host block on port2
#                      6. Create two streamblocks on port1 and port2
#                      7. Start traffic 
#                      8. Get traffic DRV results
#                      9. Get realtime results
#                      10. Stop traffic
#                      11. Get EOT results
#                      12. Cleanup sessions and release ports
#                                                                       
# Topology:
#                      STC Port2                      STC Port1                       
#                     [DHCP Server]------------------[DHCP clients]
#                     [Host Block]                                                     
#  
#                                                                          
################################################################################
# 
# Run sample:
#            c:\>robot results.robot
#

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
results test

##############################################################
#config the parameters for the logging
##############################################################
    

    ${test_sta} =  test config  log=1   logfile=results_logfile   vendorlogfile=results_stcExport   vendorlog=1   hltlog=1   hltlogfile=results_hltExport   hlt2stcmappingfile=results_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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
# Step 2: Create DHCP server and DHCP client on port2 and port1
##############################################################

    ${device_ret0} =  emulation dhcp server config  mode=create   ip_version=4   encapsulation=ETHERNET_II   remote_id=remoteId_@p-@b-@s   ipaddress_count=245   ipaddress_pool=10.1.1.10   vpn_id_count=1   vpn_id_type=nvt_ascii   circuit_id_count=1   remote_id_count=1   circuit_id=circuitId_@p   vpn_id=spirent_@p   ipaddress_increment=1   port_handle=${port2}   lease_time=3600   tos_value=192   offer_reserve_time=10   min_allowed_lease_time=600   assign_strategy=GATEWAY   host_name=server_@p-@b-@s   renewal_time_percent=50   enable_overlap_addr=false   decline_reserve_time=10   rebinding_time_percent=87.5   ip_repeat=0   remote_mac=00:00:01:00:00:01   ip_address=10.1.1.2   ip_prefix_length=24   ip_gateway=10.1.1.1   ip_step=0.0.0.1   local_mac=00:10:94:00:00:02   count=1

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp server config failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run emulation dhcp server config successfully


    ${device_ret1port} =  emulation dhcp config  mode=create   ip_version=4   port_handle=${port1}   starting_xid=0   lease_time=60   outstanding_session_count=1000   request_rate=100   msg_timeout=60000   retry_count=4   sequencetype=SEQUENTIAL   max_dhcp_msg_size=576   release_rate=100

    ${status} =  Get From Dictionary  ${device_ret1port}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp config failed\n${device_ret1port}
    ...  ELSE  Log To Console  \n***** run emulation dhcp config successfully

    ${dhcp_handle} =  Get From Dictionary  ${device_ret1port}  handles
    
    

    ${device_ret1} =  emulation dhcp group config  mode=create   dhcp_range_ip_type=4   encap=ethernet_ii   gateway_addresses=1   handle=${dhcp_handle}   host_name=client_@p-@b-@s   enable_arp_server_id=false   broadcast_bit_flag=1   opt_list=1 6 15 33 44   enable_router_option=false   gateway_ipv4_addr_step=0.0.0.0   ipv4_gateway_address=192.85.2.1   mac_addr=00:10:94:00:00:01   mac_addr_step=00:00:00:00:00:01   num_sessions=1

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

##############################################################
# Step 3: Start DHCP server and Bind DHCP device on DHCP client
##############################################################

    ${ctrl_ret1} =  emulation dhcp server control  port_handle=${port2}   action=connect   ip_version=4

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp server control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation dhcp server control successfully

    ${ctrl_ret2} =  emulation dhcp control  port_handle=${port1}   action=bind   ip_version=4

    ${status} =  Get From Dictionary  ${ctrl_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp control failed\n${ctrl_ret2}
    ...  ELSE  Log To Console  \n***** run emulation dhcp control successfully

    Sleep  5s

##############################################################
#Step 4: View DHCP info
##############################################################

    ${results_ret1} =  emulation dhcp server stats  port_handle=${port2}   action=COLLECT   ip_version=4

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp server stats failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run emulation dhcp server stats successfully, and results is:\n${results_ret1}
    

    ${results_ret2} =  emulation dhcp stats  port_handle=${port1}   action=collect   mode=detailed_session   ip_version=4

    ${status} =  Get From Dictionary  ${results_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp stats failed\n${results_ret2}
    ...  ELSE  Log To Console  \n***** run emulation dhcp stats successfully, and results is:\n${results_ret2}

    ${ipv4_addr} =  evaluate  ${results_ret2}['group']['dhcpv4blockconfig1']['1']['ipv4_addr']

    Log To Console  \nDHCP client IP : ${ipv4_addr}
    
##############################################################
#Step 5: Create a host block on port2
##############################################################

    ${hostblock} =  emulation device config  mode=create  port_handle=${port2}  intf_ip_addr=10.1.1.200  count=10  gateway_ip_addr=10.1.1.254

    ${status} =  Get From Dictionary  ${hostblock}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun sth.emulation_device_config failed\n${results_ret2}
    ...  ELSE  Log To Console  \n***** run sth.emulation_device_config successfully, and results is:\n${hostblock}

##############################################################
#Step 6: Create two streamblocks on port1 and port2
##############################################################

#get host handle from hostblock and DHCP_group_config

    ${hd1} =  Get From Dictionary  ${device_ret1}  handle
    ${hd2} =  Get From Dictionary  ${hostblock}  handle

    ${streamblock_ret1} =  traffic config  mode=create   port_handle=${port1}   port_handle2=${port2}   emulation_src_handle=${hd1}   emulation_dst_handle=${hd2}   bidirectional=1

    ${status} =  Get From Dictionary  ${streamblock_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock_ret1}
    ...  ELSE  Log To Console  \n***** run traffic config successfully

    ${streamId} =  Get From Dictionary  ${streamblock_ret1}  stream_id
    ${streamIdList} =  Get Dictionary Values  ${streamId}


##############################################################
#Step 7: Start traffic 
##############################################################

    Log To Console  \nStart traffic on port1 and port2

    ${traffic_ctrl_ret} =  traffic control  port_handle=${port1} ${port2}   action=run

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

##############################################################
#Step 8 : Get traffic DRV results
##############################################################

    ${drv_stats} =  drv stats  query_from=${port1} ${port2}  drv_name=drv1   properties=Port.Name Port.RxTotalFrameCount Port.TxTotalFrameCount  group_by=Port.Name

    ${status} =  Get From Dictionary  ${drv_stats}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun sth.drv_stats failed\n${drv_stats}
    ...  ELSE  Log To Console  \n***** Get results on port level successfully,port level results are : \n${drv_stats}

    ${drv_stats} =  drv stats  query_from=${streamIdList}  drv_name=drv2   properties=StreamBlock.PortName StreamBlock.Name StreamBlock.RxFrameCount StreamBlock.TxFrameCount   where=Streamblock.RxFrameCount != Streamblock.TxFrameCount

    ${status} =  Get From Dictionary  ${drv_stats}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun sth.drv_stats failed\n${drv_stats}
    ...  ELSE  Log To Console  \n***** Get results on port level successfully,streamblock level results are : \n${drv_stats}

########################################
# Step9. Get realtime results
########################################

    Log To Console  \nGet realtime results on port2

    ${traffic_ctrl_ret} =  traffic control  port_handle=${port1}  action=run

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

    Sleep  1s

    ${traffic_result_ret} =  traffic stats  port_handle=${port2}  mode=aggregate

    ${status} =  Get From Dictionary  ${traffic_result_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun sth.traffic_stats failed\n${traffic_result_ret}
    ...  ELSE  Log To Console  \n***** run sth.traffic_stats successfully, realtime results on port2 are:\n${traffic_result_ret}

     Sleep  5s

##############################################################
#Step 10: Stop traffic
##############################################################

    ${traffic_ctrl_ret} =  traffic control  port_handle=all  action=stop

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

##############################################################
#Step 11: Get EOT results 
##############################################################

    Log To Console  Get EOT results on port2

    ${traffic_result_ret} =  traffic stats  port_handle=${port2}  mode=aggregate

    ${status} =  Get From Dictionary  ${traffic_result_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun sth.traffic_stats failed\n${traffic_result_ret}
    ...  ELSE  Log To Console  \n***** run sth.traffic_stats successfully, EOT results on port2 are:\n${traffic_result_ret}
    
##############################################################
#Step 12: Cleanup sessions and release ports
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

