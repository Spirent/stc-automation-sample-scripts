#########################################################################################################################
#
# File Name:           rfc3918_all.robot                 
# Description:         This script demonstrates the use of Spirent HLTAPI to setup RFC3918 in B2B mode.
#                      
# Test Steps:          
#                    1. Reserve and connect chassis ports
#                    2. Create interfaces on port1 and port2 
#                    3. Create multicast group 
#                    4. Configure IGMP client on port2
#                    5. Bound IGMP client and the Multicast Group
#                    6. Create multicast and unicast streamblock 
#                    7. Create mixed_tput test and get results
#                    8. Create matrix test and get results
#                    9. Create agg_tput test and get results 
#                    10. Create fwd_latency test and get results 
#                    11. Create capacity test and get results
#                    12. Create join leave latency test and get results
#                    13. Release resources
#                                                                       
# Topology:
#                    STC Port2                      STC Port1                       
#                  [IGMP client]------------------[Multicast/Unicast groups]
#                                                                         
#  
################################################################################
# 
# Run sample:
#            c:\>robot rfc3918_all.robot
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
rfc3918 test

##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=rfc3918_all_logfile   vendorlogfile=rfc3918_all_stcExport   vendorlog=1   hltlog=1   hltlogfile=rfc3918_all_hltExport   hlt2stcmappingfile=rfc3918_all_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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
    
##############################################
# Step2. Create interfaces on port1 and port2 
##############################################

    ${int_ret0} =  interface config  mode=config   port_handle=${port1}   intf_mode=ethernet   intf_ip_addr=192.168.1.10   gateway=192.168.1.100   dst_mac_addr=00:10:94:10:00:02   src_mac_addr=00:10:94:10:00:01   resolve_gateway_mac=false

    ${status} =  Get From Dictionary  ${int_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun interface config failed\n${int_ret0}
    ...  ELSE  Log To Console  \n***** run interface config successfully

    ${hdl} =  Get From Dictionary  ${int_ret0}  handles

    ${int_ret1} =  interface config  mode=config   port_handle=${port2}   create_host=false   intf_mode=ethernet   scheduling_mode=PORT_BASED   port_loadunit=PERCENT_LINE_RATE   port_load=10   intf_ip_addr=192.168.1.100   resolve_gateway_mac=false   gateway_step=0.0.0.0   gateway=192.168.1.10   dst_mac_addr=00:10:94:10:00:01   intf_ip_addr_step=0.0.0.1   netmask=255.255.255.255   src_mac_addr_step=00:00:00:00:00:01   src_mac_addr=00:10:94:10:00:02   enable_ping_response=0   control_plane_mtu=1500   pfc_negotiate_by_dcbx=0   speed=ether10000   duplex=full   autonegotiation=1   alternate_speeds=0

    ${status} =  Get From Dictionary  ${int_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun interface config failed\n${int_ret1}
    ...  ELSE  Log To Console  \n***** run interface config successfully

########################################
# Step3. Create multicast group 
########################################

    ${groupStatus} =  emulation multicast group config  mode=create   ip_addr_start=225.0.0.1   num_groups=5

    ${status} =  Get From Dictionary  ${groupStatus}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation multicast group config failed\n${groupStatus}
    ...  ELSE  Log To Console  \n***** run emulation multicast group config successfully

    ${McGroupHandle} =  Get From Dictionary  ${groupStatus}  handle

##############################################################
# Step 4. Configure IGMP client on port2
##############################################################

    ${device_ret0} =  emulation igmp config  mode=create   port_handle=${port2}   msg_interval=2000   igmp_version=v2   robustness=2   older_version_timeout=400   unsolicited_report_interval=10   source_mac=00:10:94:10:00:02   source_mac_step=00:00:00:00:00:01   neighbor_intf_ip_addr_step=0.0.0.0   neighbor_intf_ip_addr=6.41.1.10   intf_ip_addr=6.41.1.100   intf_prefix_len=24   intf_ip_addr_step=0.0.0.1   count=1

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation igmp config failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run emulation igmp config successfully

    ${igmpSession} =  Get From Dictionary  ${device_ret0}  handle

##############################################################
# Step 5. Bound IGMP client and the Multicast Group
##############################################################
    
    Log To Console  \nBound IGMP to multicast group

    ${membershipStatus} =  emulation igmp group config  session_handle=${igmpSession}   mode=create   group_pool_handle=${McGroupHandle}

    ${status} =  Get From Dictionary  ${membershipStatus}  status
    Run Keyword If  ${status} == 0  Log To Console  \nBound the IGMP and the Multicast Group failed\n${membershipStatus}
    ...  ELSE  Log To Console  \n***** Bound the IGMP and the Multicast Group successfully\n${membershipStatus}
 
##############################################################
# Step 6. Create multicast and unicast streamblock 
############################################################## 

    ${streamblock_multicast} =  traffic config  mode=create   port_handle=${port1}   emulation_src_handle=${hdl}
    ...  emulation_dst_handle=${McGroupHandle}   l3_length=128   length_mode=fixed   mac_discovery_gw=6.41.1.100
    ...  rate_percent=10

    ${status} =  Get From Dictionary  ${streamblock_multicast}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock_multicast}
    ...  ELSE  Log To Console  \n***** run traffic config successfully\n${streamblock_multicast}

    ${streamblock_unicast} =  traffic config  mode=create   port_handle=${port1}   ip_src_addr=6.41.1.10
    ...  ip_dst_addr=6.41.1.100   l3_length=256   l3_protocol=ipv4   l2_encap=ethernet_ii   length_mode=fixed   mac_discovery_gw=6.41.1.100
    ...  rate_percent=10

    ${status} =  Get From Dictionary  ${streamblock_unicast}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock_unicast}
    ...  ELSE  Log To Console  \n***** run traffic config successfully\n${streamblock_unicast}

    ${mc_str} =  Get From Dictionary  ${streamblock_multicast}  stream_id
    ${uc_str} =  Get From Dictionary  ${streamblock_unicast}  stream_id

##############################################################
# Step 7. Create mixed_tput test and get results
##############################################################

    Log To Console  \n+++++ Start to create test 1 -- mixed class throughput test :

    ${rfc_cfg0} =  test rfc3918 config  mode=create   test_type=mixed_tput   multicast_streamblock=${mc_str}   unicast_streamblock=${uc_str}
    ...  join_group_delay=15   leave_group_delay=15   mc_msg_tx_rate=2000   latency_type=FIFO   test_duration_mode=seconds
    ...  test_duration=20   result_delay=10   start_test_delay=5   frame_size_mode=custom   frame_size=256   l2_learning_rate=100   
    ...  l3_learning_rate=200   group_count_mode=custom   group_count=60   enable_same_frame_size=1   unicast_frame_size_mode=custom
    ...  unicast_frame_size=128   mc_traffic_percent_mode=custom   mc_traffic_percent=30   initial_rate=10   rate_lower_limit=10
    ...  rate_upper_limit=10

    ${status} =  Get From Dictionary  ${rfc_cfg0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 config failed\n${rfc_cfg0}
    ...  ELSE  Log To Console  \n***** run test rfc3918 config successfully

    Log To Console  \n+++++ Start to run test 1 -- mixed class throughput test :

    ${ctrl_ret1} =  test rfc3918 control  action=run   wait=1

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc3918 control successfully

    Log To Console  \n+++++ Start to get results of test 1 -- mixed class throughput test :

    ${results_ret1} =  test rfc3918 info  test_type=mixed_tput   clear_result=0

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 info failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc3918 info successfully, and results is:\n${results_ret1}

    Log To Console  \n+++++ Start to stop test 1 -- mixed class throughput test :

    ${ctrl_ret_stop} =  test rfc3918 control  action=stop   cleanup=1

    ${status} =  Get From Dictionary  ${ctrl_ret_stop}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc3918 control successfully

##############################################################
# Step 8. Create matrix test and get results 
##############################################################

    Log To Console  \n+++++ Start to create test 2 -- scaled group forwarding matrix test :

    ${rfc_cfg0} =  test rfc3918 config  mode=create   test_type=matrix   multicast_streamblock=${mc_str}   frame_size_mode=custom
    ...  frame_size=256   load_start=10   load_end=10   join_group_delay=15   leave_group_delay=15   mc_msg_tx_rate=1000
    ...  latency_type=FIFO   test_duration_mode=seconds   test_duration=20   result_delay=10   start_test_delay=2   group_count=60

    ${status} =  Get From Dictionary  ${rfc_cfg0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 config failed\n${rfc_cfg0}
    ...  ELSE  Log To Console  \n***** run test rfc3918 config successfully

    Log To Console  \n+++++ Start to run test 2 -- scaled group forwarding matrix test :

    ${ctrl_ret1} =  test rfc3918 control  action=run   wait=1

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc3918 control successfully

    Log To Console  \n+++++ Start to get results of test 2 -- scaled group forwarding matrix test :

    ${results_ret1} =  test rfc3918 info  test_type=matrix   clear_result=0

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 info failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc3918 info successfully, and results is:\n${results_ret1}

    Log To Console  \n+++++ Start to stop test 2 -- scaled group forwarding matrix test :

    ${ctrl_ret_stop} =  test rfc3918 control  action=stop   cleanup=1

    ${status} =  Get From Dictionary  ${ctrl_ret_stop}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc3918 control successfully

##############################################################
# Step 9. Create agg_tput test and get results 
##############################################################

    Log To Console  \n+++++ Start to create test 3 -- aggregated multicast throughput test :

    ${rfc_cfg0} =  test rfc3918 config  mode=create   test_type=agg_tput   multicast_streamblock=${mc_str} 
    ...  join_group_delay=15   leave_group_delay=15   mc_msg_tx_rate=1000   latency_type=FIFO   test_duration_mode=seconds
    ...  test_duration=20   result_delay=10   start_test_delay=5   frame_size_mode=custom
    ...  frame_size=256   l2_learning_rate=100   l3_learning_rate=200   group_count_mode=custom   group_count=60   
    ...  initial_rate=10   rate_lower_limit=10   rate_upper_limit=10      

    ${status} =  Get From Dictionary  ${rfc_cfg0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 config failed\n${rfc_cfg0}
    ...  ELSE  Log To Console  \n***** run test rfc3918 config successfully

    Log To Console  \n+++++ Start to run test 3 -- aggregated multicast throughput test :

    ${ctrl_ret1} =  test rfc3918 control  action=run   wait=1

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc3918 control successfully

    Log To Console  \n+++++ Start to get results of test 3 -- aggregated multicast throughput test :

    ${results_ret1} =  test rfc3918 info  test_type=agg_tput   clear_result=0

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 info failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc3918 info successfully, and results is:\n${results_ret1}

    Log To Console  \n+++++ Start to stop test 3 -- aggregated multicast throughput test :

    ${ctrl_ret_stop} =  test rfc3918 control  action=stop   cleanup=1

    ${status} =  Get From Dictionary  ${ctrl_ret_stop}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc3918 control successfully

##############################################################
# Step 10. Create fwd_latency test and get results 
##############################################################

    Log To Console  \n+++++ Start to create test 4 -- multicast forwarding latency test :

    ${rfc_cfg0} =  test rfc3918 config  mode=create   test_type=fwd_latency   multicast_streamblock=${mc_str} 
    ...  join_group_delay=15   leave_group_delay=15   mc_msg_tx_rate=2000   latency_type=FIFO   test_duration_mode=seconds
    ...  test_duration=20   result_delay=10   start_test_delay=5   frame_size_mode=custom
    ...  frame_size=256   l2_learning_rate=100   l3_learning_rate=200   group_count_mode=custom   group_count=60   load_end=10     

    ${status} =  Get From Dictionary  ${rfc_cfg0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 config failed\n${rfc_cfg0}
    ...  ELSE  Log To Console  \n***** run test rfc3918 config successfully

    Log To Console  \n+++++ Start to run test 4 -- multicast forwarding latency test :

    ${ctrl_ret1} =  test rfc3918 control  action=run   wait=1

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc3918 control successfully

    Log To Console  \n+++++ Start to get results of test 4 -- multicast forwarding latency test :

    ${results_ret1} =  test rfc3918 info  test_type=fwd_latency   clear_result=0

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 info failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc3918 info successfully, and results is:\n${results_ret1}

    Log To Console  \n+++++ Start to stop test 4 -- multicast forwarding latency test :

    ${ctrl_ret_stop} =  test rfc3918 control  action=stop   cleanup=1

    ${status} =  Get From Dictionary  ${ctrl_ret_stop}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc3918 control successfully

##############################################################
# Step 11. Create capacity test and get results
##############################################################

    Log To Console  \n+++++ Start to create test 5 -- multicast group capacity test :

    ${rfc_cfg0} =  test rfc3918 config  mode=create   test_type=capacity   multicast_streamblock=${mc_str} 
    ...  join_group_delay=15   leave_group_delay=15   mc_msg_tx_rate=2000   latency_type=FIFO   test_duration_mode=seconds
    ...  test_duration=20   result_delay=10   start_test_delay=5   group_upper_limit=10   frame_size=256   load_end=10   

    ${status} =  Get From Dictionary  ${rfc_cfg0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 config failed\n${rfc_cfg0}
    ...  ELSE  Log To Console  \n***** run test rfc3918 config successfully

    Log To Console  \n+++++ Start to run test 5 -- multicast group capacity test :

    ${ctrl_ret1} =  test rfc3918 control  action=run   wait=1

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc3918 control successfully

    Log To Console  \n+++++ Start to get results of test 5 -- multicast group capacity test :

    ${results_ret1} =  test rfc3918 info  test_type=capacity   clear_result=0

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 info failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc3918 info successfully, and results is:\n${results_ret1}

    Log To Console  \n+++++ Start to stop test 5 -- multicast group capacity test :

    ${ctrl_ret_stop} =  test rfc3918 control  action=stop   cleanup=1

    ${status} =  Get From Dictionary  ${ctrl_ret_stop}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc3918 control successfully

##############################################################
# Step 12. Create join leave latency test and get results
##############################################################

    Log To Console  \n+++++ Start to create test 6 -- join leave latency test :

    ${rfc_cfg0} =  test rfc3918 config  mode=create   test_type=join_latency  multicast_streamblock=${mc_str} 
    ...  join_group_delay=15   leave_group_delay=15   mc_msg_tx_rate=2000   latency_type=FIFO   test_duration_mode=seconds
    ...  test_duration=20   result_delay=10   start_test_delay=5   group_count=60   frame_size=256   load_end=10   

    ${status} =  Get From Dictionary  ${rfc_cfg0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 config failed\n${rfc_cfg0}
    ...  ELSE  Log To Console  \n***** run test rfc3918 config successfully

    Log To Console  \n+++++ Start to run test 6 -- join leave latency test :

    ${ctrl_ret1} =  test rfc3918 control  action=run   wait=1

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc3918 control successfully

    Log To Console  \n+++++ Start to get results of test 6 -- join leave latency test :

    ${results_ret1} =  test rfc3918 info  test_type=join_latency   clear_result=0

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 info failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc3918 info successfully, and results is:\n${results_ret1}

    Log To Console  \n+++++ Start to stop test 6 -- join leave latency test :

    ${ctrl_ret_stop} =  test rfc3918 control  action=stop   cleanup=1

    ${status} =  Get From Dictionary  ${ctrl_ret_stop}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun test rfc3918 control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run test rfc3918 control successfully

#config part is finished

##############################################################
# Step 13. Release resources
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

