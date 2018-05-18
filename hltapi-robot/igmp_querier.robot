################################################################################
#
# File Name:         igmp_querier.robot
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup Igmp Router.
#
# Test Step:          1. Reserve and connect chassis ports
#                     2. Configure IGMP Querier(router) on port1
#                     3. Configure IGMP Host on port2
#                     4. Setup Multicast group
#                     5. Attach multicast group to IGMP Host
#                     6. Start capture on all ports
#                     7. Join IGMP hosts to multicast group
#                     8. Get IGMP hosts Stats
#                     9. Start IGMP Querier
#                     10. Get the IGMP Querier Stats
#                     11. Check and Display IGMP router states
#                     12. Stop IGMP Querier
#                     13. Leave IGMP Host from the Multicast Group
#                     14. Stop the packet capture 
#                     15. Delete IGMP Querier 
#                     16. Release Resources
#
#
# Topology
#                   STC Port1                      STC Port2                       
#                [IGMP Queriers]-------------------[IGMP Hosts]
#                                              
################################################################################
# Run sample:
#            c:\>robot igmp_querier.robot

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
igmp querier test
    
##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=igmp_querier_logfile   vendorlogfile=igmp_querier_stcExport   vendorlog=1   hltlog=1   hltlogfile=igmp_querier_hltExport   hlt2stcmappingfile=igmp_querier_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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
# Step 2. Configure IGMP Querier(router) on port1
##############################################################

    Log To Console  Create 7 igmp querier routers on port1

    ${device_ret0} =  emulation igmp querier config  mode=create   port_handle=${port1}   count=7   ipv4_tos=192   query_interval=125   ipv4_dont_fragment=false   igmp_version=v2   last_member_query_interval=1000   robustness_variable=2   startup_query_count=2   query_response_interval=10000   last_member_query_count=2   ignore_v1_reports=false   use_partial_block_state=false   vlan_user_priority=7   vlan_cfi=0   vlan_id=111   vlan_id_count=3   vlan_id_step=2   vlan_id_mode=increment      vlan_outer_user_priority=7   vlan_outer_cfi=0   vlan_id_outer=101   vlan_id_outer_count=5   vlan_id_outer_step=2   vlan_id_outer_mode=increment   source_mac=00:10:94:00:00:02   neighbor_intf_ip_addr=1.1.1.10   neighbor_intf_ip_addr_step=0.0.0.1   intf_ip_addr=1.1.1.40   intf_ip_addr_step=0.0.0.1   intf_prefix_len=24   tos_type=tos

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation igmp querier config failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run emulation igmp querier config successfully

    ${igmpQuerierRouterList} =  Get From Dictionary  ${device_ret0}  handle

##############################################################
# Step 3. Configure IGMP Host on port2
##############################################################

    Log To Console  Create 7 igmp hosts on port2

    ${device_ret7} =  emulation igmp config  mode=create   port_handle=${port2}   count=7   igmp_version=v2   robustness=10   
    ...  intf_ip_addr=1.1.1.10   intf_ip_addr_step=0.0.0.1   neighbor_intf_ip_addr=1.1.1.40   neighbor_intf_ip_addr_step=0.0.0.1   
    ...  vlan_id=111   vlan_id_count=3   vlan_id_step=2   vlan_id_mode=increment   vlan_id_outer=101   vlan_id_outer_count=5
    ...  vlan_id_outer_step=2   vlan_id_outer_mode=increment   qinq_incr_mode=outer   general_query=1   general_query=1   

    ${status} =  Get From Dictionary  ${device_ret7}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation igmp config failed\n${device_ret7}
    ...  ELSE  Log To Console  \n***** run emulation igmp config successfully

    ${igmpHostHandle} =  Get From Dictionary  ${device_ret7}  handle

##############################################################
# Step 4. Setup Multicast group
##############################################################

    ${device_ret7_macstgroup_1} =  emulation multicast group config  mode=create   ip_prefix_len=32   ip_addr_start=225.1.0.1   ip_addr_step=1   num_groups=1   pool_name=Ipv4Group_1

    ${status} =  Get From Dictionary  ${device_ret7_macstgroup_1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation multicast group config failed\n${device_ret7_macstgroup_1}
    ...  ELSE  Log To Console  \n***** run emulation multicast group config successfully

    ${mcGroupHandle} =  Get From Dictionary  ${device_ret7_macstgroup_1}  handle
    
##############################################################
# Step 5. Attach multicast group to IGMP Host
##############################################################   

    ${device_ret7_group_config1} =  emulation igmp group config  session_handle=${igmpHostHandle}   mode=create   group_pool_handle=${mcGroupHandle}

    ${status} =  Get From Dictionary  ${device_ret7_group_config1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nAttached Multicast Group to Host failed\n${device_ret7_group_config1}
    ...  ELSE  Log To Console  \n***** Attached Multicast Group to Host successfully

##############################################################
# Step 6. Start capture on all ports
##############################################################

    Log To Console  \nStart to capture

    ${packet_control} =  packet control  port_handle=all  action=start

    ${status} =  Get From Dictionary  ${packet_control}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun packet control failed\n${packet_control}
    ...  ELSE  Log To Console  \n***** run packet control successfully

##############################################################
# Step 7. Join IGMP hosts to multicast group
##############################################################

    ${ctrl_ret2} =  emulation igmp control  handle=${igmpHostHandle}   mode=join

    ${status} =  Get From Dictionary  ${ctrl_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nStarted(Join) IGMP Host failed\n${ctrl_ret2}
    ...  ELSE  Log To Console  \n***** Started(Join) IGMP Host successfully

    Sleep  5s

#config part is finished

##############################################################
# Step 8. Get IGMP hosts Stats
##############################################################

    ${results_ret2} =  emulation igmp info  handle=${igmpHostHandle}   mode=stats

    ${status} =  Get From Dictionary  ${results_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation igmp info failed\n${results_ret2}
    ...  ELSE  Log To Console  \n***** run emulation igmp info successfully, and results is:\n${results_ret2}

##############################################################
# Step 9. Start IGMP Querier
##############################################################

    ${ctrl_ret1} =  emulation igmp querier control  port_handle=${port1}   mode=start

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation igmp querier control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation igmp querier control successfully

    Sleep  5s

##############################################################
# Step 10. Get the IGMP Querier Stats
##############################################################

    ${igmpQuerierInfo} =  emulation igmp querier info  port_handle=${port1}

    ${status} =  Get From Dictionary  ${igmpQuerierInfo}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation igmp querier info failed\n${igmpQuerierInfo}
    ...  ELSE  Log To Console  \n***** run emulation igmp querier info successfully, and results is:\n${igmpQuerierInfo}
    
##############################################################
# Step 11. Check and Display IGMP router states
##############################################################

    @{igmpQuerierRouterList} =  Split String  ${igmpQuerierRouterList}

    :FOR  ${router}  IN  @{igmpQuerierRouterList}
    \  ${routerState} =  evaluate  ${igmpQuerierInfo}['results']['${router}']['router_state'] 
    \  Log To Console  \nState of ${router} is : ${routerState}
    \  Run Keyword If  '${routerState}' != 'UP'  Log To Console  IGMP Querier ${router} is not UP

##############################################################
# Step 12. Stop IGMP Querier
##############################################################

    ${ctrl_ret1} =  emulation igmp querier control  port_handle=${port1}   mode=stop

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nStop IGMP Querier failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** Stop IGMP Querier successfully

##############################################################
# Step 13. Leave IGMP Host from the Multicast Group
##############################################################

    ${ctrl_ret2} =  emulation igmp control  handle=${igmpHostHandle}   mode=leave

    ${status} =  Get From Dictionary  ${ctrl_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nIGMP Hosts left IGMP group failed\n${ctrl_ret2}
    ...  ELSE  Log To Console  \n***** IGMP Hosts left IGMP group successfully

##############################################################
# Step 14. Stop the packet capture
##############################################################

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
# Step 15. Delete IGMP Querier
##############################################################

    ${ctrl_ret1} =  emulation igmp querier config  handle=${igmpQuerierRouterList}   mode=delete

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nDelete IGMP Querier failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** Delete IGMP Querier successfully

##############################################################
# Step 16. Release resources
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

