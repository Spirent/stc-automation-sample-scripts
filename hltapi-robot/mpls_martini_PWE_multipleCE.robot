#########################################################################################################################
#
# File Name:           mpls_martini_PWE_multipleCE.robot                 
# Description:         This script demonstrates the use of Spirent HLTAPI to setup MPLS L2VPN in martini method.
#                      
# Test Steps:          
#             1.Reserve and connect chassis ports
#             2.Configure interfaces
#             3.Configure OSPF router on port2
#             4.Configure OSPF IPv4 LSA
#             5.Configure LDP router on port2
#             6.Configure LDP IPv4 Prefix
#             7.Start LDP router
#             8.Configure MPLS L2VPN PE on port2
#             9.Create MPLS L2VPN CE on port1 
#             10.Create MPLS L2VPN CE on port2
#             11.Create MPLS L2VPN traffic
#             12.Start OSPF router
#             13.Start catpure and start traffic
#             14.Stop traffic and stop catpure
#             15.Get traffic statistics
#             16. Release resources
#
#                                                                       
# Topology:
#    loop: 4.4.4.4/32      loop: 220.1.1.1/32          loop:2.2.2.4/32             loop:3.3.3.4/32
#      _                            _                          _                           _
#      |                            |                          |                           |
#      |                            |                          |                           |
#      |                            |                          |                           |
#   [STC Port1]              13/31 DUT 13/32               [STC Port2]                [STC Port2]
#     [CE]------------------------[PE]------------------------[PE]------------------------[CE]
#         .11                   .1    .1                   .11    .1                   .11
#                13.31.0.0/16               13.32.0.0/16                 120.1.1.0/24
#     BGP1001                     BGP123                     BGP123                      BGP1001
#
################################################################################
# 
# Run sample:
#            c:\>robot mpls_martini_PWE_multipleCE.robot
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
mpls_martini_PWE_multipleCE Test
    [Documentation]  mpls_martini_PWE_multipleCE Test
    
##############################################################
#config the parameters for the logging
##############################################################

    ${test_sta} =  test config  log=1   logfile=mpls_martini_PWE_multipleCE_logfile   vendorlogfile=mpls_martini_PWE_multipleCE_stcExport   vendorlog=1   hltlog=1   hltlogfile=mpls_martini_PWE_multipleCE_hltExport   hlt2stcmappingfile=mpls_martini_PWE_multipleCE_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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
# Step2.Configure interfaces
########################################

    ${int_ret0} =  interface config  mode=config   port_handle=${port1}   create_host=false   intf_mode=ethernet   phy_mode=fiber   scheduling_mode=RATE_BASED   port_loadunit=PERCENT_LINE_RATE   port_load=10   enable_ping_response=0   control_plane_mtu=1500   flow_control=false   speed=ether1000   data_path_mode=normal   autonegotiation=1

    ${status} =  Get From Dictionary  ${int_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun interface config failed\n${int_ret0}
    ...  ELSE  Log To Console  \n***** run interface config successfully

    ${int_ret1} =  interface config  mode=config   port_handle=${port2}   create_host=false   intf_mode=ethernet   phy_mode=fiber   scheduling_mode=RATE_BASED   port_loadunit=PERCENT_LINE_RATE   port_load=10   enable_ping_response=0   control_plane_mtu=1500   flow_control=false   speed=ether1000   data_path_mode=normal   autonegotiation=1

    ${status} =  Get From Dictionary  ${int_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun interface config failed\n${int_ret1}
    ...  ELSE  Log To Console  \n***** run interface config successfully

##############################################################
# Step3.Configure OSPF router on port2
##############################################################

    #start to create the device: Router 1

    ${device_ret0} =  emulation ospf config  mode=create   session_type=ospfv2   authentication_mode=none   network_type=native   option_bits=0x2   port_handle=${port2}   router_id=13.32.0.11   mac_address_start=00:10:94:00:00:32   intf_ip_addr=13.32.0.11   gateway_ip_addr=13.32.0.1   intf_prefix_length=16   hello_interval=30   lsa_retransmit_delay=5   te_metric=0   router_priority=12   te_enable=0   dead_interval=120   interface_cost=1   area_id=0.0.0.0   graceful_restart_enable=false

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ospf config failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** run emulation ospf config successfully

    ${ospfRouterPE} =  Get From Dictionary  ${device_ret0}  handle

############################################
# Telnet to DUT to config OSPF protocol
############################################
#EX_TelnetOpen $DUTIP $dutUserName $dutPassWord -timeout 5 -passwordPrompt "Password:" -prompt ">"
#EX_TelnetSendCommand "en" -prompt "Password:"
#EX_TelnetSendCommand $enablePassword -prompt "#"
#EX_TelnetSendCommand "configure terminal"

#EX_TelnetSendCommand "interface gigabitEthernet 13/31"
#EX_TelnetSendCommand "ip ospf network broadcast"
#EX_TelnetSendCommand "interface gigabitEthernet 13/31"
#EX_TelnetSendCommand "ip ospf network broadcast"

#EX_TelnetClose
############################################

##############################################################
# Step4.Configure OSPF IPv4 LSA
##############################################################
#Create OSPF router LSA on the Provide side 

    ${device_ret0_router0} =  emulation ospf lsa config  type=router   router_virtual_link_endpt=0   router_route_category=undefined   router_asbr=1   adv_router_id=2.2.2.4   link_state_id=255.255.255.255   router_abr=0   handle=${ospfRouterPE}   router_link_mode=create   router_link_data=255.255.255.255   router_link_id=2.2.2.4   router_link_metric=1   router_link_count=1   router_link_type=stub   mode=create

    ${status} =  Get From Dictionary  ${device_ret0_router0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ospf lsa config failed\n${device_ret0_router0}
    ...  ELSE  Log To Console  \n***** run emulation ospf lsa config successfully

##############################################################
# Step5.Configure LDP router on port2
##############################################################

    ${device_cfg_ret0} =  emulation ldp config  mode=create   handle=${ospfRouterPE}   ip_version=ipv4   hello_interval=5   directed_hello_interval=5   ldp_version=version_1   label_request_retry_count=10   remote_ip_addr=220.1.1.1   generalized_pwid_lsp_label_binding_mode=tx_and_rx   label_request_retry_interval=30   prefix_lsp_label_binding_mode=tx_and_rx   hello_version=ipv4   label_adv=unsolicited   enable_stateful_pseudowire_lsp_results=0   vc_lsp_label_binding_mode=tx_and_rx   targeted_hello_interval=5   use_static_flow_label=0   keepalive_interval=45   peer_discovery=targeted   label_start=39   reconnect_time=60   graceful_restart=0   enable_lsp_results=1   liveness_time=360   graceful_recovery_timer=140   recovery_time=140   transport_tlv_mode=tester_ip   egress_label_mode=nextlabel   pseudowire_redundancy_mode=none   adjacency_version=ipv4

    ${status} =  Get From Dictionary  ${device_cfg_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ldp config failed\n${device_cfg_ret0}
    ...  ELSE  Log To Console  \n***** run emulation ldp config successfully

    ${ldpRouterPE} =  Get From Dictionary  ${device_cfg_ret0}  handle

############################################
# Telnet to DUT to config LDP protocol
############################################
#EX_TelnetOpen $DUTIP $dutUserName $dutPassWord -timeout 5 -passwordPrompt "Password:" -prompt ">"
#EX_TelnetSendCommand "en" -prompt "Password:"
#EX_TelnetSendCommand $enablePassword -prompt "#"
#EX_TelnetSendCommand "configure terminal"

#EX_TelnetSendCommand "interface gigabitEthernet 13/32"
#EX_TelnetSendCommand "mpls label protocol ldp"
#EX_TelnetSendCommand "mpls ip"

#EX_TelnetClose
############################################

##############################################################
# Step6.Configure LDP IPv4 Prefix
##############################################################

    ${device_cfg_ret0_route0} =  emulation ldp route config  mode=create   handle=${ldpRouterPE}   lsp_type=ipv4_egress   fec_type=prefix   fec_ip_prefix_step=1   fec_ip_prefix_length=24   fec_ip_prefix_start=120.1.1.1   num_routes=1

    ${status} =  Get From Dictionary  ${device_cfg_ret0_route0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ldp route config failed\n${device_cfg_ret0_route0}
    ...  ELSE  Log To Console  \n***** run emulation ldp route config successfully

##############################################################
# Step7.Start LDP router
##############################################################

    ${ctrl_ret2} =  emulation ldp control  handle=${ldpRouterPE}   mode=start

    ${status} =  Get From Dictionary  ${ctrl_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ldp control failed\n${ctrl_ret2}
    ...  ELSE  Log To Console  \n***** run emulation ldp control successfully

##############################################################
# Step8.Configure MPLS L2VPN PE on port2
##############################################################
    Log To Console  \nConfigure PE router

    ${pe_ret} =  emulation mpls l2vpn pe config  mode=enable  port_handle=${port2}  vpn_type=martini_pwe  igp_session_handle=${ospfRouterPE}
    ...  targeted_ldp_session_handle=${ldpRouterPE}  mpls_session_handle=${ldpRouterPE}  pe_count=1

    ${status} =  Get From Dictionary  ${pe_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation mpls l2vpn pe config failed\n${pe_ret}
    ...  ELSE  Log To Console  \n***** run run emulation mpls l2vpn pe config successfully

    ${VPNRouterPE} =  Get From Dictionary  ${pe_ret}  handle

##############################################################
# Step9.Create MPLS L2VPN CE on port1 
##############################################################

    Log To Console  \nCreate MPLS CE on left side

    ${ce_site} =  emulation mpls l2vpn site config  mode=create   port_handle=${port1}   pe_loopback_ip_addr=220.1.1.1   pe_loopback_ip_step=0.0.0.0   pe_loopback_ip_prefix=32   site_count=1   vpn_id=100   vc_id=1500

    ${status} =  Get From Dictionary  ${ce_site}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation vpls site config failed\n${ce_site}
    ...  ELSE  Log To Console  \n***** run emulation vpls site config successfully

    ${ceCustomSide} =  Get From Dictionary  ${ce_site}  handle

##############################################################
# Step10.Create MPLS L2VPN CE on port2
##############################################################

    Log To Console  \nCreate CE on right side

    ${ce_site} =  emulation mpls l2vpn site config  mode=create   pe_handle=${vpnRouterPE}   vpn_id=100   vpn_type=martini_pwe   pe_loopback_ip_prefix=32   vc_id=1500   vc_id_step=1   pe_loopback_ip_addr=2.2.2.4   vc_id_count=1   port_handle=${port2}   vlan_id=1701   vlan_id_step=0   vlan_id_count=1   mac_addr=00:10:94:00:00:34   mac_addr_step=00:00:00:00:00:01

    ${status} =  Get From Dictionary  ${ce_site}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation mpls l2vpn site config failed\n${ce_site}
    ...  ELSE  Log To Console  \n***** run emulation mpls l2vpn site config successfully

    ${ceProvideSide} =  Get From Dictionary  ${ce_site}  handle

############################################
# Telnet to DUT to config VRF
############################################
#EX_TelnetOpen $DUTIP $dutUserName $dutPassWord -timeout 5 -passwordPrompt "Password:" -prompt ">"
#EX_TelnetSendCommand "en" -prompt "Password:"
#EX_TelnetSendCommand $enablePassword -prompt "#"
#EX_TelnetSendCommand "configure terminal"

#EX_TelnetSendCommand "interface gigabitEthernet 13/31"
#EX_TelnetSendCommand "ip vrf forwarding vpn123"
#EX_TelnetSendCommand "ip address 13.31.0.1 255.255.0.0"

#EX_TelnetClose
    
##############################################################
# Step11.Create MPLS L2VPN traffic
##############################################################

    Log To Console  \nCreate traffic from left CE to right CE

    ${streamblock_ret1} =  traffic config  mode=create   port_handle=${port1}   l3_length=256  length_mode=fixed   rate_pps=10   
    ...  emulation_src_handle=${ceCustomSide}  emulation_dst_handle=${ceProvideSide}

    ${status} =  Get From Dictionary  ${streamblock_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock_ret1}
    ...  ELSE  Log To Console  \n***** run traffic config successfully

    Log To Console  \nCreate traffic from right CE to left CE

    ${streamblock_ret1} =  traffic config  mode=create   port_handle=${port2}   l3_length=256  length_mode=fixed   rate_pps=10   
    ...  emulation_dst_handle=${ceCustomSide}   emulation_src_handle=${ceProvideSide}

    ${status} =  Get From Dictionary  ${streamblock_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock_ret1}
    ...  ELSE  Log To Console  \n***** run traffic config successfully

    #config part is finished
    
##############################################################
# Step12.Start OSPF router
##############################################################

    Log To Console  \nStart OSPF router

    ${ctrl_ret1} =  emulation ospf control  handle=${ospfRouterPE}   mode=start

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ospf control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation ospf control successfully

    Sleep  20s

##############################################################
# Step13.Start catpure and start traffic
##############################################################
    
    Log To Console  \nStart capture

    ${packet_control} =  packet control  port_handle=all  action=start

    ${status} =  Get From Dictionary  ${packet_control}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun packet control failed\n${packet_control}
    ...  ELSE  Log To Console  \n***** run packet control successfully

    Log To Console  \nStart traffic on port1 and port2

    ${traffic_ctrl_ret} =  traffic control  port_handle=${port1} ${port2}   action=run

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully,the return is:${traffic_ctrl_ret}

    Sleep  10s

##############################################################
# Step14.Stop traffic and stop catpure
##############################################################
    
    Log To Console  \nStop traffic on port1 and port2

    ${traffic_ctrl_ret} =  traffic control  port_handle=${port1} ${port2}   action=stop

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully,the return is:${traffic_ctrl_ret}

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
# Step15.Get traffic statistics
##############################################################

    ${port2_stats} =  interface stats  port_handle=${port2}

    ${status} =  Get From Dictionary  ${port2_stats}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun interface stats failed\n${port2_stats}
    ...  ELSE  Log To Console  \n***** run run interface stats successfully, and results is:\n${port2_stats}

    ${port1_stats} =  interface stats  port_handle=${port1}

    ${status} =  Get From Dictionary  ${port1_stats}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun interface stats failed\n${port1_stats}
    ...  ELSE  Log To Console  \n***** run run interface stats successfully, and results is:\n${port1_stats}
    
##############################################################
# Step16. Release resources
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************

