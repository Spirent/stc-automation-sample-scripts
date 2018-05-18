################################################################################
#
# File Name:         igmpol2tp.robot
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup IGMP over L2TP test.
#
# Test Steps:         1. Reserve and connect chassis ports
#                     2. Configure LAC on port1
#                     3. Enable IGMP on LAC 
#                     4. Configure multicast group
#                     5. Bound the IGMP and the Multicast Group
#                     6. Configure downstream traffic : port2 -> port1
#                     7. Join IGMP to multicast group
#                     8. Get IGMP Stats
#                     9. Start capture
#                    10. Start traffic
#                    11. Stop traffic
#                    12. Stop and save capture
#                    13. Verify interface stats
#                    14. Configure IGMP Host leave from Multicast Group
#                    15. Start traffic again
#                    16. Verify port stats after IGMP host leaving multicast group
#                    17. Release resources
#
# Topology:
#                LAC(STC port1)----------------DUT------------IPv4 Host(STC port2)
#                   172.16.0.2       172.16.0.1   172.17.0.1      172.17.0.2
# DUT Config:
#    vpdn enable
#    vpdn-group 1
#     accept dialin l2tp virtual-template 10 remote HosLAC
#     local name HosLNS
#     no l2tp tunnel authentication
#     l2tp tunnel receive-window 1024
#     l2tp tunnel framing capabilities all
#     l2tp tunnel bearer capabilities all
#    
#    ip local pool rui_ippool 10.88.55.1 10.88.55.10
#    
#    interface virtual-template 10
#     ip address 10.88.55.11 255.255.255.0
#     peer default ip address pool rui_ippool
#     no ppp authentication
#     ppp timeout idle 42000
#                                              
################################################################################
# 
# Run sample:
#            c:\>robot igmpol2tp.robot

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
igmp over l2tp test

##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=igmpol2tp_logfile   vendorlogfile=igmpol2tp_stcExport   vendorlog=1   hltlog=1   hltlogfile=igmpol2tp_hltExport   hlt2stcmappingfile=igmpol2tp_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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
# Step 2. Configure LAC on port1
##############################################################
    
    Log To Console  \nCreate LAC on port1

    ${device_ret0} =  l2tp config  mode=lac   port_handle=${port1}   hostname=HosLAC   auth_mode=none   l2_encap=ethernet_ii
    ...  l2tp_src_addr=172.16.0.2   l2tp_dst_addr=172.16.0.1   num_tunnels=1   sessions_per_tunnel=1   hello_interval=255
    ...  hello_req=TRUE   redial_timeout=10   redial_max=3

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun l2tp config failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run l2tp config successfully

    ${lac_handles} =  Get From Dictionary  ${device_ret0}  handles

##############################################################
# Step 2. Connect LAC and get LAC stats
##############################################################    
    
    Log To Console  \nConnect LAC

    ${ctrl_ret1} =  l2tp control  handle=${lac_handles}   action=connect

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun l2tp control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run l2tp control successfully\n${ctrl_ret1}

    Log To Console  \nGet l2tp LAC stats

    ${results_ret1} =  l2tp stats  handle=${lac_handles}   mode=aggregate

    ${status} =  Get From Dictionary  ${results_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun l2tp stats failed\n${results_ret1}
    ...  ELSE  Log To Console  \n***** run l2tp stats successfully, and results is:\n${results_ret1}

##############################################################
# Step 3. Enable IGMP on LAC 
##############################################################

    Log To Console  \nEnable IGMP on LAC

    ${device_cfg_ret0} =  emulation igmp config  mode=create   handle=${lac_handles}   older_version_timeout=400
    ...  robustness=2   unsolicited_report_interval=10   igmp_version=v3

    ${status} =  Get From Dictionary  ${device_cfg_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation igmp config failed\n${device_cfg_ret0}
    ...  ELSE  Log To Console  \n***** run emulation igmp config successfully

    ${igmpSession} =  Get From Dictionary  ${device_cfg_ret0}  handle

##############################################################
# Step 4. Configure multicast group
##############################################################

    Log To Console  \nConfigure multicast group

    ${groupStatus} =  emulation multicast group config  mode=create   ip_addr_start=225.0.0.25  num_groups=1

    ${status} =  Get From Dictionary  ${groupStatus}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation multicast group config failed\n${groupStatus}
    ...  ELSE  Log To Console  \n***** run emulation multicast group config successfully

    ${igmpGroup} =  Get From Dictionary  ${groupStatus}  handle

##############################################################
# Step 5. Bound the IGMP and the Multicast Group
##############################################################

    Log To Console  \nBound IGMP to multicast group

    ${membershipStatus} =  emulation igmp group config  session_handle=${igmpSession}   mode=create   group_pool_handle=${igmpGroup}

    ${status} =  Get From Dictionary  ${membershipStatus}  status
    Run Keyword If  ${status} == 0  Log To Console  \nBound the IGMP and the Multicast Group failed\n${membershipStatus}
    ...  ELSE  Log To Console  \n***** Bound the IGMP and the Multicast Group successfully\n${membershipStatus}

##############################################################
# Step 6. Configure downstream traffic : port2 -> port1
##############################################################

    Log To Console  \nConfigure downstream traffic : port2 -> port1

    ${streamblock_ret1} =  traffic config  mode=create   port_handle=${port2}   rate_pps=1000   l2_encap=ethernet_ii   l3_protocol=ipv4
    ...  l3_length=108   transmit_mode=continuous   length_mode=fixed   ip_src_addr=172.17.0.2   ip_dst_addr=225.0.0.25

    ${status} =  Get From Dictionary  ${streamblock_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock_ret1}
    ...  ELSE  Log To Console  \n***** run traffic config successfully\n${streamblock_ret1}

##############################################################
# Step 7. Join IGMP to multicast group
##############################################################

    Log To Console  \nJoin IGMP to multicast group

    ${ctrl_ret2} =  emulation igmp control  handle=${igmpSession}   mode=join

    ${status} =  Get From Dictionary  ${ctrl_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nJoin IGMP to multicast group failed\n${ctrl_ret2}
    ...  ELSE  Log To Console  \n***** Join IGMP to multicast group successfully\n${ctrl_ret2}

    Sleep  5s

#config part is finished

##############################################################
# Step 8. Get IGMP Stats
##############################################################

    Log To Console  \nGet IGMP Stats

    ${results_ret2} =  emulation igmp info  handle=${igmpSession}   mode=stats

    ${status} =  Get From Dictionary  ${results_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation igmp info failed\n${results_ret2}
    ...  ELSE  Log To Console  \n***** run emulation igmp info successfully, and results is:\n${results_ret2}

##############################################################
# Step 9. Start capture
##############################################################

    Log To Console  \nStart to capture

    ${packet_control} =  packet control  port_handle=all  action=start

    ${status} =  Get From Dictionary  ${packet_control}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun packet control failed\n${packet_control}
    ...  ELSE  Log To Console  \n***** run packet control successfully

##############################################################
# Step 10. Start traffic
##############################################################

    Log To Console  \nStart traffic on all ports

    ${traffic_ctrl_ret} =  traffic control  port_handle=all   action=run

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

##############################################################
# Step 11. Stop traffic
##############################################################

    Log To Console  \nStop traffic on all ports

    ${traffic_ctrl_ret} =  traffic control  port_handle=all   action=stop

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

##############################################################
# Step 12. Stop and save capture
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
# Step 13. Verify interface stats
##############################################################

    Log To Console  \nVerify interface stats

    ${int_stats} =  interface stats  port_handle=${port2}

    ${status} =  Get From Dictionary  ${int_stats}  status
    Run Keyword If  ${status} == 0  Log To Console  \nGet interface stats failed\n${int_stats}
    ...  ELSE  Log To Console  \n***** Get interface stats successfully,the stats are:${int_stats}

    ${int_stats} =  interface stats  port_handle=${port1}

    ${status} =  Get From Dictionary  ${int_stats}  status
    Run Keyword If  ${status} == 0  Log To Console  \nGet interface stats failed\n${int_stats}
    ...  ELSE  Log To Console  \n***** Get interface stats successfully,the stats are:${int_stats}

##############################################################
# Step 14. Configure IGMP Host leave from Multicast Group
##############################################################

    Log To Console  \nLeave IGMP Hosts from the Multicast Group

    ${ctrl_ret2} =  emulation igmp control  handle=${igmpSession}   mode=leave

    ${status} =  Get From Dictionary  ${ctrl_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nIGMP Hosts left IGMP group failed\n${ctrl_ret2}
    ...  ELSE  Log To Console  \n***** IGMP Hosts left IGMP group successfully

##############################################################
# Step 15. Start traffic again
############################################################## 

    Log To Console  \nStart traffic again

    ${traffic_ctrl_ret} =  traffic control  port_handle=all   action=run

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

####################################################################
# Step 16. Verify port stats after IGMP host leaving multicast group
####################################################################

    Log To Console  \nVerify port stats after IGMP host leaving multicast group

    ${int_stats} =  interface stats  port_handle=${port2}

    ${status} =  Get From Dictionary  ${int_stats}  status
    Run Keyword If  ${status} == 0  Log To Console  \nGet interface stats failed\n${int_stats}
    ...  ELSE  Log To Console  \n***** Get interface stats successfully,the stats are:${int_stats}

    ${int_stats} =  interface stats  port_handle=${port1}

    ${status} =  Get From Dictionary  ${int_stats}  status
    Run Keyword If  ${status} == 0  Log To Console  \nGet interface stats failed\n${int_stats}
    ...  ELSE  Log To Console  \n***** Get interface stats successfully,the stats are:${int_stats}

##############################################################
# Step 17. Release resources
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

