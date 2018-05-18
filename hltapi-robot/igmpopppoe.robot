################################################################################
#
# File Name:         igmpopppoe.robot
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup IGMP over PPPoE.
#
# Test Steps:        1. Reserve and connect chassis ports
#                    2. Configure interface on port2
#                    3. Connect PPPoE on port1
#                    4. Configure IGMP over PPPoE on Port1
#                    5. Configure Multicast group
#                    6. Bound the IGMP and the Multicast Group
#                    7. Connect PPPoE client and check status
#                    8. Join IGMP to multicast group
#                    9. Get IGMP Stats
#                    10. Setup ipv4 multicast traffic
#                    11. Start capture
#                    12. Start traffic
#                    13. Stop traffic
#                    14. Stop and save capture
#                    15. Get traffic statistics
#                    16. Release resources
#
# Topology:
#               IGMPoPPPoE Client        PTA                Host
#                   STC port1  --------- DUT ----------- STC port2 
# 
################################################################################
# 
# Run sample:
#            c:\>robot igmpopppoe.robot

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
igmp over pppoe test

##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=igmpopppoe_logfile   vendorlogfile=igmpopppoe_stcExport   vendorlog=1   hltlog=1   hltlogfile=igmpopppoe_hltExport   hlt2stcmappingfile=igmpopppoe_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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
# Step 2. Configure interface on port2
##############################################################

    ${int_ret1} =  interface config  mode=config   port_handle=${port2}   intf_ip_addr=20.0.0.2   autonegotiation=1    gateway=20.0.0.1
    ...  arp_send_req=1   arp_req_retries=10

    ${status} =  Get From Dictionary  ${int_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun interface config failed\n${int_ret1}
    ...  ELSE  Log To Console  \n***** run interface config successfully\n${int_ret1}

##############################################################
# Step 3. Connect PPPoE on port1
##############################################################
    Log To Console  \nConnect PPPoE on port1

    ${device_ret0} =  pppox config  mode=create   encap=ethernet_ii   protocol=pppoe   ac_select_mode=service_name   circuit_id_suffix_mode=none   port_handle=${port1}   max_outstanding=100   disconnect_rate=1000   attempt_rate=100   pppoe_circuit_id=circuit   mru_neg_enable=1   max_configure_req=10   chap_ack_timeout=10   max_padi_req=10   padi_include_tag=1   padr_req_timeout=3   max_terminate_req=10   term_req_timeout=3   username=spirent   use_partial_block_state=false   max_auto_retry_count=10   agent_type=2516   max_ipcp_req=10   intermediate_agent=false   echo_req_interval=10   password=spirent   local_magic=1   config_req_timeout=10   active=1   auto_retry=1   padi_req_timeout=3   agent_mac_addr=00:00:00:00:00:00   lcp_mru=1492   ip_cp=ipv4_cp   auto_fill_ipv6=1   max_echo_acks=10   auth_mode=chap   include_id=1   ipcp_req_timeout=10   max_padr_req=10   padr_include_tag=1   echo_req=false   fsm_max_naks=5   mac_addr=00:10:94:01:00:01   mac_addr_repeat=0   mac_addr_step=00:00:00:00:00:01   intf_ip_addr=192.85.1.3   gateway_ip_addr=192.85.1.1   intf_ip_addr_step=0.0.0.1   gateway_ip_step=0.0.0.0   num_sessions=1

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun pppox config failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run pppox config successfully

    ${pppox_handles} =  Get From Dictionary  ${device_ret0}  handles

##############################################################
# Step 4. Configure IGMP over PPPoE on Port1
##############################################################   
    Log To Console  \nConfig IGMP over PPPoE on Port1

    ${device_cfg_ret0} =  emulation igmp config  mode=create   handle=${pppox_handles}   igmp_version=v2   robustness=2   older_version_timeout=400   unsolicited_report_interval=10

    ${status} =  Get From Dictionary  ${device_cfg_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation igmp config failed\n${device_cfg_ret0}
    ...  ELSE  Log To Console  \n***** run emulation igmp config successfully

    ${igmp_session} =  Get From Dictionary  ${device_cfg_ret0}  handle

##############################################################
# Step 5. Configure Multicast group
##############################################################
    Log To Console  \nConfigure Multicast group

    ${groupStatus} =  emulation multicast group config  mode=create   ip_addr_start=225.0.0.25   num_groups=1

    ${status} =  Get From Dictionary  ${groupStatus}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation multicast group config failed\n${groupStatus}
    ...  ELSE  Log To Console  \n***** run emulation multicast group config successfully
    
    ${igmpGroup} =  Get From Dictionary  ${groupStatus}  handle
    
##############################################################
# Step 6. Bound the IGMP and the Multicast Group
##############################################################    
    Log To Console  \nBound IGMP to multicast group

    ${membershipStatus} =  emulation igmp group config  session_handle=${igmpSession}   mode=create   group_pool_handle=${igmpGroup}  

    ${status} =  Get From Dictionary  ${membershipStatus}  status
    Run Keyword If  ${status} == 0  Log To Console  \nBound the IGMP and the Multicast Group failed\n${membershipStatus}
    ...  ELSE  Log To Console  \n***** Bound the IGMP and the Multicast Group successfully

#config part is finished
    
##############################################################
# Step 7. Connect PPPoE client and check status
##############################################################

    Log To Console  \nConnect PPPoE Client

    ${ctrl_ret1} =  pppox control  handle=${pppox_handles}   action=connect

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun pppox control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run pppox control successfully

    Sleep  10s

    Log To Console  \nCheck PPPoE client status

    ${results_ret1} =  pppox stats  handle=${pppox_handles}   mode=aggregate

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun pppox stats failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run pppox stats successfully, and results is:\n${results_ret1}

##############################################################
# Step 8. Join IGMP to multicast group
##############################################################

    Log To Console  \nJoin IGMP to multicast group

    ${ctrl_ret2} =  emulation igmp control  handle=${igmpSession}   mode=join

    ${status} =  Get From Dictionary  ${ctrl_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nJoin IGMP to multicast group failed\n${ctrl_ret2}
    ...  ELSE  Log To Console  \n***** Join IGMP to multicast group successfully\n${ctrl_ret2}

    Sleep  5s

##############################################################
# Step 9. Get IGMP Stats
##############################################################

    Log To Console  \nGet IGMP stats

    ${results_ret2} =  emulation igmp info  handle=${igmpSession}   mode=stats

    ${status} =  Get From Dictionary  ${results_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation igmp info failed\n${results_ret2}
    ...  ELSE  Log To Console  \n***** run emulation igmp info successfully, and results is:\n${results_ret2}

##############################################################
# Step 10. Setup ipv4 multicast traffic
############################################################## 

    Log To Console  \nSetup ipv4 multicast traffics

    ${streamblock_ret1} =  traffic config  mode=create   port_handle=${port2}   rate_pps=1000   l2_encap=ethernet_ii   l3_protocol=ipv4
    ...  l3_length=128   transmit_mode=continuous   length_mode=fixed   ip_src_addr=20.0.0.2   emulation_dst_handle=${igmpGroup}

    ${status} =  Get From Dictionary  ${streamblock_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock_ret1}
    ...  ELSE  Log To Console  \n***** run traffic config successfully\n${streamblock_ret1}

    ${stream_down_id} =  Get From Dictionary  ${streamblock_ret1}  stream_id

##############################################################
# Step 11. Start capture
##############################################################

    Log To Console  \nStart to capture

    ${packet_control} =  packet control  port_handle=all  action=start

    ${status} =  Get From Dictionary  ${packet_control}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun packet control failed\n${packet_control}
    ...  ELSE  Log To Console  \n***** run packet control successfully

##############################################################
# Step 12. Start traffic
##############################################################

    Log To Console  \nStart traffic on port2

    ${traffic_ctrl_ret} =  traffic control  port_handle=${port2}   action=run

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully\n${traffic_ctrl_ret}

##############################################################
# Step 13. Stop traffic
##############################################################

    Log To Console  \nStop traffic on port2

    ${traffic_ctrl_ret} =  traffic control  port_handle=${port2}   action=stop

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully\n{traffic_ctrl_ret}

##############################################################
# Step 14. Stop and save capture
##############################################################

    Log To Console  \nStop capture and save packets

    ${packet_stats1} =  packet stats  port_handle=${port1}  action=filtered  stop=1  format=pcap  filename=port1.pcap

    ${status} =  Get From Dictionary  ${packet_stats1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun packet control failed\n${packet_stats1}
    ...  ELSE  Log To Console  \n***** run packet control successfully

##############################################################
# Step 15. Get traffic statistics
##############################################################

    Log To Console  \nGet traffic statistics

    ${traffic_results_ret} =  traffic stats  streams=${stream_down_id}   mode=streams

    ${status} =  Get From Dictionary  ${traffic_results_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic stats failed\n${traffic_results_ret}
    ...  ELSE  Log To Console  \n***** run traffic stats successfully, and results is:\n${traffic_results_ret}

##############################################################
# Step 16. Release resources
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

