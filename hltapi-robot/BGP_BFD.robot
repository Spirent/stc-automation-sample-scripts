#################################
#
# File Name:         BGP_BFD.robot
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup BFD on BGP routers.
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Config BGP router with BFD enabled
#                    3. Start BGP router
#                    4. Check BGP status
#                    5. Disable BFD 
#                    6. Telnet DUT to check neighbor status of BFD
#                    7. Release resources
# 
# DUT configuration:
#           router bgp 123
#             bgp router-id 220.1.1.1
#             neighbor 100.1.0.8 remote-as 1
#             neighbor 100.1.0.8 fall-over bfd
#           !
#          interface FastEthernet1/0
#            ip address 100.1.0.1 255.255.255.0
#            duplex full
#            bfd interval 500 min_rx 500 multiplier 3
#          !
#
#
# Topology
#                 STC Port1                            Cisco DUT                       
#                [BGP router]---------------------[BGP router(BFD enabled)]
#                                 100.1.0.0/24
#                                         
#
#################################

# Run sample:
#            c:\>robot BGP_BFD.robot


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
BGP BFD Test

##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=BGP_BFD_logfile   vendorlogfile=BGP_BFD_stcExport   vendorlog=1   hltlog=1   hltlogfile=BGP_BFD_hltExport   hlt2stcmappingfile=BGP_BFD_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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
# Step 2.Config BGP router with BFD enabled
##############################################################

    #start to create the device: Device 1

    ${device_ret0} =  emulation bgp config  mode=enable   retries=100   vpls_version=VERSION_00   routes_per_msg=2000   staggered_start_time=100   update_interval=30   retry_time=30   staggered_start_enable=1   md5_key_id=1   md5_key=Spirent   md5_enable=0   ipv4_unicast_nlri=1   ip_stack_version=4   port_handle=${port1}   bgp_session_ip_addr=interface_ip   remote_ip_addr=100.1.0.1   ip_version=4   view_routes=0   remote_as=123   hold_time=90   restart_time=90   route_refresh=0   local_as=1   active_connect_enable=1   bfd_registration=1   stale_time=90   graceful_restart_enable=0   local_router_id=22.1.1.2   next_hop_ip=100.1.0.1   local_ip_addr=100.1.0.8   netmask=24   mac_address_start=00:10:94:00:00:02

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation bgp config failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run emulation bgp config successfully

    ${bgpHandle} =  Get From Dictionary  ${device_ret0}  handles

    #config part is finished
    
##############################################################
# Step 3.start BGP router
##############################################################

    ${ctrl_ret1} =  emulation bgp control  handle=${bgpHandle}   mode=start

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation bgp control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation bgp control successfully

    Sleep  5s

##############################################################
# Step 4. Check BGP status
##############################################################

    ${results_ret1} =  emulation bgp info  handle=${bgpHandle}   mode=stats

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation bgp info failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run emulation bgp info successfully, and results is:\n${results_ret1}

########################################
# Step5: Disable BFD 
########################################

    ${device_ret0} =  emulation bgp config  mode=modify   bfd_registration=0   handle=${bgpHandle}

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun sth.emulation_bgp_disable_bfd failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run sth.emulation_bgp_disable_bfd successfully

# Step6: Telnet DUT to check neighbor status of BFD

##############################################################
# Step 7. Release resources
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

