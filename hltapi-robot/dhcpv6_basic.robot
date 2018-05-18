################################################################################
#
# File Name:         dhcpv6_basic.robot
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup DHCPv6 Client/Server test.
#                    In this test, DHCP Server and clients are emulated in back-to-back mode.
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Interface config (optional)
#                    3. Config dhcpv6 server host
#                    4. Config dhcpv6 client 
#                    5. Start dhcpv6 server
#                    6. Bound Dhcpv6 clients
#                    7  Retrive Dhcpv6 session results
#                    8. Stop Dhcpv6 server and client
#                    9. Release resources
#
#
# Topology
#                   STC Port1                      STC Port2                       
#                [DHCPv6 Server]------------------[DHCPv6 clients]
#                                                                               
#
################################################################################

# Run sample:
#            c:\>robot dhcpv6_basic.robot

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
dhcpv6 basic test

##############################################################
#config the parameters for the logging
##############################################################
    

    ${test_sta} =  test config  log=1   logfile=dhcpv6_basic_logfile   vendorlogfile=dhcpv6_basic_stcExport   vendorlog=1   hltlog=1   hltlogfile=dhcpv6_basic_hltExport   hlt2stcmappingfile=dhcpv6_basic_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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

#########################################
## Step3: Config dhcpv6 server host
#########################################

    ${device_ret0} =  emulation dhcp server config  mode=create   ip_version=6   encapsulation=ethernet_ii   prefix_pool_step=1   prefix_pool_per_server=100   prefix_pool_start_addr=2002::1   prefix_pool_step_per_server=0:0:0:1::   prefix_pool_prefix_length=64   addr_pool_host_step=::1   addr_pool_addresses_per_server=100   addr_pool_start_addr=2000::1   addr_pool_prefix_length=64   addr_pool_step_per_server=1   port_handle=${port2}   preferred_lifetime=604800   enable_delayed_auth=false   valid_lifetime=2592000   dhcp_realm=spirent.com   enable_reconfigure_key=false   reneval_time_percent=50   rebinding_time_percent=80   server_emulation_mode=DHCPV6   local_ipv6_prefix_len=64   local_ipv6_addr=2012::2   gateway_ipv6_addr_step=::   local_ipv6_addr_step=::1   gateway_ipv6_addr=2012::1   mac_addr=00:10:94:00:00:04   mac_addr_step=00:00:00:00:00:01   count=1

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp server config failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run emulation dhcp server config successfully

    ${dhcpserver_handle} =  evaluate  ${device_ret0}['handle']['dhcpv6_handle']

#########################################
## Step4: Config dhcpv6 client
#########################################

    ${device_ret1port} =  emulation dhcp config  mode=create   ip_version=6   port_handle=${port1}   dhcp6_renew_rate=100   dhcp6_request_rate=100   dhcp6_rel_max_rc=5   dhcp6_dec_max_rc=5   dhcp6_indef_rel_rt=false   dhcp6_inforeq_max_rt=120   dhcp6_req_timeout=1   dhcp6_sol_max_rc=10   dhcp6_reb_timeout=10   dhcp6_ren_max_rt=600   dhcp6_cfm_max_rt=4   dhcp6_indef_sol_rt=false   dhcp6_sol_max_rt=120   dhcp6_inforeq_timeout=1   dhcp6_dec_timeout=1   dhcp6_reb_max_rt=600   dhcp6_cfm_timeout=1   dhcp6_release_rate=100   dhcp6_sol_timeout=1   dhcp6_rel_timeout=1   dhcp6_req_max_rc=10   dhcp6_indef_req_rt=false   dhcp6_sequence_type=SEQUENTIAL   dhcp6_req_max_rt=30   dhcp6_cfm_duration=10   dhcp6_outstanding_session_count=1   dhcp6_ren_timeout=10

    ${status} =  Get From Dictionary  ${device_ret1port}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp config failed\n${device_ret1port}
    ...  ELSE  Log To Console  \n***** run emulation dhcp config successfully

    ${dhcp_handle} =  Get From Dictionary  ${device_ret1port}  handles

    ${device_ret1} =  emulation dhcp group config  mode=create   dhcp_range_ip_type=6   encap=ethernet_ii   handle=${dhcp_handle}   enable_reconfig_accept=false   preferred_lifetime=604800   use_relay_agent_mac_addr_for_dataplane=true   enable_relay_agent=false   relay_server_ipv6_addr_step=::   dhcp6_range_duid_type=LLT   prefix_length=0   duid_value=1   enable_rebind=false   dhcp6_range_duid_vendor_id_increment=1   prefix_start=::   dad_transmits=1   control_plane_prefix=LINKLOCAL   enable_remote_id=false   valid_lifetime=2592000   dhcp_realm=spirent.com   enable_auth=false   requested_addr_start=::   client_mac_addr_mask=00:00:00:ff:ff:ff   enable_dad=true   dhcp6_range_duid_enterprise_id=3456   dhcp6_range_ia_t1=302400   dst_addr_type=ALL_DHCP_RELAY_AGENTS_AND_SERVERS   dhcp6_range_ia_t2=483840   client_mac_addr=00:10:01:00:00:01   enable_renew=true   enable_ldra=false   dad_timeout=1   client_mac_addr_step=00:00:00:00:00:01   rapid_commit_mode=DISABLE   dhcp6_client_mode=DHCPV6   dhcp6_range_duid_vendor_id=0001   local_ipv6_prefix_len=64   local_ipv6_addr=2009::2   gateway_ipv6_addr_step=::   local_ipv6_addr_step=::1   gateway_ipv6_addr=2005::1   mac_addr=00:00:10:95:11:15   mac_addr_step=00:00:00:00:00:01   num_sessions=20

    ${status} =  Get From Dictionary  ${device_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp group config failed\n${device_ret1}
    ...  ELSE  Log To Console  \n***** run emulation dhcp group config successfully

#config part is finished
    
#########################################
## Step5: Start Dhcp Server 
#########################################

    ${ctrl_ret1} =  emulation dhcp server control  port_handle=${port2}   action=connect   ip_version=6

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp server control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation dhcp server control successfully

#########################################
## Step6: Bound Dhcp clients
#########################################

    ${ctrl_ret2} =  emulation dhcp control  port_handle=${port1}   action=bind   ip_version=6

    ${status} =  Get From Dictionary  ${ctrl_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp control failed\n${ctrl_ret2}
    ...  ELSE  Log To Console  \n***** run emulation dhcp control successfully

    Sleep  15s
    
############################################################
## Step7: Retrive Dhcpv6 Client and Server results
############################################################

    ${results_ret1} =  emulation dhcp server stats  port_handle=${port2}   action=COLLECT   ip_version=6

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp server stats failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run emulation dhcp server stats successfully, and results is:\n${results_ret1}
    

    ${results_ret2} =  emulation dhcp stats  port_handle=${port1}   action=collect   mode=detailed_session   ip_version=6

    ${status} =  Get From Dictionary  ${results_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp stats failed\n${results_ret2}
    ...  ELSE  Log To Console  \n***** run emulation dhcp stats successfully, and results is:\n${results_ret2}

#########################################
## Step8: Stop Dhcpv6 server and client
#########################################    

    ${ctrl_ret1} =  emulation dhcp server control  port_handle=${port2}   action=reset   ip_version=6

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp server control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation dhcp server control successfully

    ${ctrl_ret2} =  emulation dhcp control  port_handle=${port1}   action=release   ip_version=6

    ${status} =  Get From Dictionary  ${ctrl_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation dhcp control failed\n${ctrl_ret2}
    ...  ELSE  Log To Console  \n***** run emulation dhcp control successfully

########################################
#step9: Release resources
########################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

