#################################
#
# File Name:         dhcp_server_relay_agent.robot
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup DHCP Server test.
#                    In this test, DHCP Server assigns ip addresses to DHCP clients in different network through Relay agent.
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Interface config (optional)
#                    3. Config dhcp server host
#                    4. Config dhcp server relay agent pool
#                    5. Config dhcpv4 client 
#                    6. Start dhcp server
#                    7. Bound Dhcp clients
#                    8. Retrive Dhcp session results
#                    9. Stop Dhcp server and client
#                    10. Release resources
#
# DUT configuration:
#
#             ip dhcp relay information option
#             ip dhcp relay information trust-all
#             !
#             interface FastEthernet 1/0
#               ip address 100.1.0.1 255.255.255.0
#               duplex full
#
#            interface FastEthernet 2/0
#              ip address 110.0.0.1 255.255.255.0
#              ip helper-address 100.1.0.8
#              duplex full
#
# Topology
#                 STC Port1        DHCP Relay Agent            STC Port2                       
#             [DHCP Server]---------------[DUT]--------------[DHCP clients]
#                           100.1.0.0/24         110.0.0.0/24    
#                                         
#
#################################
# Run sample:
#            c:\>robot dhcp_server_relay_agent.robot
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
dhcp relay agent test

##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=dhcp_server_relay_agent_logfile   vendorlogfile=dhcp_server_relay_agent_stcExport   vendorlog=1   hltlog=1   hltlogfile=dhcp_server_relay_agent_hltExport   hlt2stcmappingfile=dhcp_server_relay_agent_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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

########################################
# Step2: Interface config
########################################

    ${int_ret0} =  interface config  mode=config   port_handle=${port1}   create_host=false   intf_mode=ethernet   phy_mode=copper   scheduling_mode=RATE_BASED   port_loadunit=PERCENT_LINE_RATE   port_load=10   enable_ping_response=0   control_plane_mtu=1500   pfc_negotiate_by_dcbx=0   speed=ether10000   duplex=full   autonegotiation=1   alternate_speeds=0

    ${status} =  Get From Dictionary  ${int_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun interface config failed\n${int_ret0}
    ...  ELSE  Log To Console  \n***** run interface config successfully

    ${int_ret1} =  interface config  mode=config   port_handle=${port2}   create_host=false   intf_mode=ethernet   phy_mode=copper   scheduling_mode=RATE_BASED   port_loadunit=PERCENT_LINE_RATE   port_load=10   enable_ping_response=0   control_plane_mtu=1500   pfc_negotiate_by_dcbx=0   speed=ether10000   duplex=full   autonegotiation=1   alternate_speeds=0

    ${status} =  Get From Dictionary  ${int_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun interface config failed\n${int_ret1}
    ...  ELSE  Log To Console  \n***** run interface config successfully

########################################
# Step3: Config dhcp server host
########################################

    ${device_ret0} =  emulation dhcp server config  mode=create   ip_version=4   encapsulation=ETHERNET_II   remote_id=remoteId_@p-@b-@s   ipaddress_count=245   ipaddress_pool=100.1.0.9   vpn_id_count=1   vpn_id_type=nvt_ascii   circuit_id_count=1   remote_id_count=1   circuit_id=circuitId_@p   vpn_id=spirent_@p   ipaddress_increment=1   port_handle=${port2}   lease_time=60   tos_value=192   offer_reserve_time=10   min_allowed_lease_time=600   assign_strategy=GATEWAY   host_name=server_@p-@b-@s   renewal_time_percent=50   enable_overlap_addr=false   decline_reserve_time=10   rebinding_time_percent=87.5   ip_repeat=0   remote_mac=00:00:01:00:00:01   ip_address=100.1.0.8   ip_prefix_length=24   ip_gateway=100.1.0.1   ip_step=0.0.0.1   local_mac=00:10:94:00:00:02   count=1

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp server config failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run emulation dhcp server config successfully

    ${dhcpserver_handle} =  Get From Dictionary  ${device_ret0}  handle
    ${dhcpserver_handle} =  Get From Dictionary  ${dhcpserver_handle}  dhcp_handle
    
###############################################
# Step4: Config dhcp server relay agent pool
###############################################   

    ${device_ret0_agent0} =  emulation dhcp server relay agent config  mode=create   relay_agent_pool_count=2   relay_agent_pool_step=1.0.0.0   handle=${dhcpserver_handle}   vpn_id_count=1   remote_id_count=1   relay_agent_ipaddress_count=50   relay_agent_ipaddress_pool=110.0.0.5   circuit_id=circuitId_@p   vpn_id=spirent_@p   remote_id=remoteId_@p-@b-@s   vpn_id_type=nvt_ascii   relay_agent_ipaddress_step=0.0.0.1   circuit_id_count=1   prefix_length=24

    ${status} =  Get From Dictionary  ${device_ret0_agent0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp server relay agent config failed\n${device_ret0_agent0}
    ...  ELSE  Log To Console  \n***** run emulation dhcp server relay agent config successfully

########################################
# Step5: Config dhcpv4 client
########################################

    ${device_ret1port} =  emulation dhcp config  mode=create   ip_version=4   port_handle=${port1}   starting_xid=0   lease_time=60   outstanding_session_count=1000   request_rate=100   msg_timeout=60000   retry_count=4   sequencetype=SEQUENTIAL   max_dhcp_msg_size=576   release_rate=100

    ${status} =  Get From Dictionary  ${device_ret1port}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp config failed\n${device_ret1port}
    ...  ELSE  Log To Console  \n***** run emulation dhcp config successfully

    ${dhcp_handle} =  Get From Dictionary  ${device_ret1port}  handles

    ${device_ret1} =  emulation dhcp group config  mode=create   dhcp_range_ip_type=4   encap=ethernet_ii   gateway_addresses=1   handle=${dhcp_handle}   host_name=client_@p-@b-@s   enable_arp_server_id=false   broadcast_bit_flag=1   opt_list=1 6 15 33 44   enable_router_option=false   gateway_ipv4_addr_step=0.0.0.0   ipv4_gateway_address=192.85.2.1   mac_addr=00:00:10:95:11:15   mac_addr_step=00:00:00:00:00:01   num_sessions=20

    ${status} =  Get From Dictionary  ${device_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp group config failed\n${device_ret1}
    ...  ELSE  Log To Console  \n***** run emulation dhcp group config successfully

    #config part is finished
    
########################################
# Step6: Start Dhcp Server 
######################################## 

    ${ctrl_ret1} =  emulation dhcp server control  port_handle=${port2}   action=connect   ip_version=4

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp server control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation dhcp server control successfully

########################################
# Step7: Bound Dhcp clients
########################################

    ${ctrl_ret2} =  emulation dhcp control  port_handle=${port1}   action=bind   ip_version=4

    ${status} =  Get From Dictionary  ${ctrl_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp control failed\n${ctrl_ret2}
    ...  ELSE  Log To Console  \n***** run emulation dhcp control successfully

    Sleep  5s
  
########################################
# Step8: Retrive Dhcp session results
########################################

    ${results_ret1} =  emulation dhcp server stats  port_handle=${port2}   action=COLLECT   ip_version=4

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp server stats failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run emulation dhcp server stats successfully, and results is:\n${results_ret1}

    ${results_ret2} =  emulation dhcp stats  port_handle=${port1}   action=collect   mode=detailed_session   ip_version=4

    ${status} =  Get From Dictionary  ${results_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp stats failed\n${results_ret2}
    ...  ELSE  Log To Console  \n***** run emulation dhcp stats successfully, and results is:\n${results_ret2}

########################################
# Step9: Stop Dhcp server and client
########################################

    ${ctrl_ret1} =  emulation dhcp server control  port_handle=${port2}   action=reset   ip_version=4

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp server control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation dhcp server control successfully

    ${ctrl_ret2} =  emulation dhcp control  port_handle=${port1}   action=release   ip_version=4

    ${status} =  Get From Dictionary  ${ctrl_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp control failed\n${ctrl_ret2}
    ...  ELSE  Log To Console  \n***** run emulation dhcp control successfully

########################################
#step10: Release resources
########################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

