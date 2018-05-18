#########################################################################################################################
#
# File Name:           mpls_l3vpn_ldp_multipleCE.robot                 
# Description:         This script demonstrates the use of Spirent HLTAPI to setup MPLS L3VPN in BGP/OSPF scenario.
#                      
# Test Steps:          
#             1.Reserve and connect chassis ports
#             2.Configure interfaces
#             3.Configure OSPF router on port2
#             4.Configure OSPF IPv4 LSA
#             5.Start OSPF router
#             6.Configure BGP router on CE router on port1
#             7.Configure BGP router on PE router on port2
#             8.Configure BGP prefix
#             9.Start BGP router on port1 and port2
#             10.Configure LDP router on port2
#             11.Configure LDP IPv4 Prefix
#             12.Start LDP router
#             13.Configure MPLS L3VPN PE on port2
#             14.Create MPLS L3VPN CE on port1 
#             15.Create MPLS L3VPN CE on port2
#             16.Create MPLS L3VPN traffic
#             17.Start catpure and start traffic
#             18.Stop traffic and stop catpure
#             19.Get traffic statistics
#             20. Release resources
#
#                                                                       
# Topology:
#    loop: 4.4.4.4/32      loop: 220.1.1.1/32          loop:2.2.2.4/32             loop:3.3.3.4/32
#      _                            _                          _                           _
#      |                            |                          |                           |
#      |                            |                          |                           |
#      |                            |                          |                           |
#   [STC Port1]              13/31 DUT 13/32              [STC Port2]                [STC Port2]
#     [CE]------------------------[PE]------------------------[PE]------------------------[CE]
#         .11                   .1    .1                   .11    .1                   .11
#                13.31.0.0/16               13.32.0.0/16                 120.1.1.0/24
#     BGP1001                     BGP123                     BGP123                      BGP1001
#
################################################################################
# 
# Run sample:
#            c:\>robot mpls_l3vpn_ldp_multipleCE.robot
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
mpls l3vpn ldp multipleCE test

##############################################################
#config the parameters for the logging
##############################################################
    

    ${test_sta} =  test config  log=1   logfile=mpls_l3vpn_ldp_multipleCE_logfile   vendorlogfile=mpls_l3vpn_ldp_multipleCE_stcExport   vendorlog=1   hltlog=1   hltlogfile=mpls_l3vpn_ldp_multipleCE_hltExport   hlt2stcmappingfile=mpls_l3vpn_ldp_multipleCE_hlt2StcMapping   hlt2stcmapping=1   log_level=7

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

     ${device_cfg_ret0} =  emulation ospf config  mode=create   port_handle=${port2}   session_type=ospfv2   authentication_mode=none   network_type=native   option_bits=0x2   hello_interval=30   lsa_retransmit_delay=5   te_metric=0   router_priority=12   te_enable=0   dead_interval=120   interface_cost=1   area_id=0.0.0.0   graceful_restart_enable=false   router_id=2.2.2.4   gateway_ip_addr=13.32.0.1
    ...  intf_ip_addr=13.32.0.11

    ${status} =  Get From Dictionary  ${device_cfg_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ospf config failed\n${device_cfg_ret0}
    ...  ELSE  Log To Console  \n***** run emulation ospf config successfully

    ${ospfRouterPE} =  Get From Dictionary  ${device_cfg_ret0}  handle

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

    ${device_cfg_ret0_router0} =  emulation ospf lsa config  type=router   router_virtual_link_endpt=0   router_route_category=undefined   router_asbr=1   adv_router_id=2.2.2.4   link_state_id=255.255.255.255   router_abr=0   handle=${ospfRouterPE}   router_link_mode=create   router_link_data=255.255.255.255   router_link_id=2.2.2.4   router_link_metric=1   router_link_count=1   router_link_type=stub   mode=create

    ${status} =  Get From Dictionary  ${device_cfg_ret0_router0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ospf lsa config failed\n${device_cfg_ret0_router0}
    ...  ELSE  Log To Console  \n***** run emulation ospf lsa config successfully

##############################################################
# Step5.Start OSPF router
##############################################################

    Log To Console  Start OSPF router
    ${ctrl_ret3} =  emulation ospf control  handle=${ospfRouterPE}   mode=start

    ${status} =  Get From Dictionary  ${ctrl_ret3}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation ospf control failed\n${ctrl_ret3}
    ...  ELSE  Log To Console  \n***** run emulation ospf control successfully

    Sleep  10s

##############################################################
# Step6.Configure BGP router on CE router on port1
##############################################################

    Log To Console  Start BGP router

#-Config BGP on CE router(Customer Side)
#-Note: Please set the "-remote_ip_addr" to be the gateway, not the DUT's loopback1, because there are no IGP can broadcast the loopback1 address to CE.

     ${device_ret1} =  emulation bgp config  mode=enable   retries=100   vpls_version=VERSION_00   routes_per_msg=2000   staggered_start_time=100   update_interval=30   retry_time=30   staggered_start_enable=1   md5_key_id=1   md5_key=Spirent   md5_enable=0   ipv4_unicast_nlri=1   ip_stack_version=4   port_handle=${port1}   bgp_session_ip_addr=interface_ip   remote_ip_addr=13.31.0.1   ip_version=4   view_routes=0   remote_as=123   hold_time=90   restart_time=90   route_refresh=0   local_as=1001   active_connect_enable=1   stale_time=90   graceful_restart_enable=0   local_router_id=4.4.4.4   next_hop_ip=13.31.0.1   local_ip_addr=13.31.0.11   netmask=16   mac_address_start=00:10:94:00:00:31

    ${status} =  Get From Dictionary  ${device_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nFailed to configure BGP on customer side CE.\n${device_ret1}
    ...  ELSE  Log To Console  \n*****Configure BGP on customer side CE successfully.

    ${bgpRouterCE} =  Get From Dictionary  ${device_ret1}  handle

############################################
# Telnet to DUT to config BGP protocol
############################################
#EX_TelnetOpen $DUTIP $dutUserName $dutPassWord -timeout 5 -passwordPrompt "Password:" -prompt ">"
#EX_TelnetSendCommand "en" -prompt "Password:"
#EX_TelnetSendCommand $enablePassword -prompt "#"
#EX_TelnetSendCommand "configure terminal"

#EX_TelnetSendCommand "router bgp 123"
#EX_TelnetSendCommand "address-family ipv4 vrf vpn123"
#EX_TelnetSendCommand "neighbor 13.31.0.11 remote-as 1001"
#EX_TelnetSendCommand "neighbor 13.31.0.11 update-source Loopback1"
#EX_TelnetSendCommand "neighbor 13.31.0.11 activate"

#EX_TelnetClose
############################################

##############################################################
# Step7.Configure BGP router on PE router on port2
##############################################################
#---------------------------------------------------------------------------------------------------------------------------------------------#
#-Note1: For the LDP and BGP can not work together on the same router handle, we perform DBD to solve the VPN label problem,
# so we should create BGP router behind the LDP router, and specify the BGP's "-local_ip_addr" and "-next_hop_ip" to be the router-id.
#
#-Note2: For the BGP router's special address, we should use the router id to specify the BGP router neighbour on the DUT, for example:
# neighbor 2.2.2.4 remote-as 123
# neighbor 2.2.2.4 update-source Loopback1
# address-family vpnv4
# neighbor 2.2.2.4 activate
# neighbor 2.2.2.4 send-community extended
#---------------------------------------------------------------------------------------------------------------------------------------------#

    ${device_ret2} =  emulation bgp config  mode=enable   handle=${ospfRouterPE}   active_connect_enable=1   local_as=123   remote_as=123   
    ...  remote_ip_addr=220.1.1.1   ipv4_mpls_vpn_nlri=1   ip_version=4      

    ${status} =  Get From Dictionary  ${device_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nFailed to configure BGP on provider side PE.\n${device_ret2}
    ...  ELSE  Log To Console  \n***** Configure BGP on provider side PE successfully.

    ${bgpRouterPE} =  Get From Dictionary  ${device_ret2}  handle

############################################
# Telnet to DUT to config BGP protocol
############################################
#EX_TelnetOpen $DUTIP $dutUserName $dutPassWord -timeout 5 -passwordPrompt "Password:" -prompt ">"
#EX_TelnetSendCommand "en" -prompt "Password:"
#EX_TelnetSendCommand $enablePassword -prompt "#"
#EX_TelnetSendCommand "configure terminal"

#EX_TelnetSendCommand "router bgp 123"
#EX_TelnetSendCommand "neighbor 2.2.2.4 remote-as 123"
#EX_TelnetSendCommand "neighbor 2.2.2.4 update-source Loopback1"
#EX_TelnetSendCommand "address-family vpnv4"
#EX_TelnetSendCommand "neighbor 2.2.2.4 activate"
#EX_TelnetSendCommand "neighbor 2.2.2.4 send-community extended"

#EX_TelnetClose
############################################
     
##############################################################
# Step8.Configure BGP prefix
##############################################################

    Log To Console  Create BGP prefix on CE router

    ${device_ret1_route1} =  emulation bgp route config  handle=${bgpRouterCE}   mode=add   ip_version=4   as_path=as_seq:1001   target_type=as   target=100   target_assign=1   rd_type=0   rd_admin_step=0   rd_admin_value=100   rd_assign_step=1   rd_assign_value=1   next_hop_ip_version=4   next_hop_set_mode=manual   ipv4_unicast_nlri=1   prefix=101.101.1.1   netmask=255.255.255.0   prefix_step=1   num_routes=1   next_hop=13.31.0.11   atomic_aggregate=0   local_pref=10   route_category=undefined   label_incr_mode=none   origin=igp

    ${status} =  Get From Dictionary  ${device_ret1_route1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nFailed to create BGP prefix on CE router\n${device_ret1_route1}
    ...  ELSE  Log To Console  \n***** Create BGP prefix on CE router successfully

    Log To Console  Create BGP prefix on PE router

    ${device_ret0_route1} =  emulation bgp route config  handle=${bgpRouterPE}   mode=add   ip_version=4   as_path=as_seq:123   target_type=as   target=123   target_assign=1   rd_type=0   rd_admin_step=0   rd_admin_value=123   rd_assign_step=1   rd_assign_value=1   next_hop_ip_version=4   next_hop_set_mode=manual   ipv4_mpls_vpn_nlri=1   prefix=120.1.1.1   netmask=255.255.255.0   prefix_step=1   num_routes=1   next_hop=13.32.0.11   atomic_aggregate=0   local_pref=10   route_category=undefined   label_incr_mode=none   origin=igp

    ${status} =  Get From Dictionary  ${device_ret0_route1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nFailed to create BGP prefix on PE router\n${device_ret0_route1}
    ...  ELSE  Log To Console  \n***** Create BGP prefix on PE router successfully

##############################################################
# Step9.Start BGP router on port1 and port2
##############################################################

    Log To Console  Start BGP router on CE and PE

    ${ctrl_ret1} =  emulation bgp control  handle=${bgpRouterCE}   mode=start

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation bgp control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation bgp control successfully

    ${ctrl_ret1} =  emulation bgp control  handle=${bgpRouterPE}   mode=start

    ${status} =  Get From Dictionary  ${ctrl_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun emulation bgp control failed\n${ctrl_ret1}
    ...  ELSE  Log To Console  \n***** run emulation bgp control successfully

    Sleep  5s

##############################################################
# Step10.Configure LDP router on port2
##############################################################

    Log To Console  "Configure LDP on PE router"  

    ${device_cfg_ret1} =  emulation ldp config  mode=create   handle=${ospfRouterPE}   peer_discovery=link   
    ...  label_adv=unsolicited   label_start=39   intf_ip_addr=13.32.0.11   intf_prefix_length=16   gateway_ip_addr=13.32.0.1
    ...  lsr_id=2.2.2.4

    ${status} =  Get From Dictionary  ${device_cfg_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nFailed to create LDP router\n${device_cfg_ret1}
    ...  ELSE  Log To Console  \n*****Create LDP router successfully

    ${ldpRouterPE} =  Get From Dictionary  ${device_cfg_ret1}  handle

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
# Step11.Configure LDP IPv4 Prefix
##############################################################

    Log To Console  Configure LSP on PE router 

    ${device_cfg_ret0_route0} =  emulation ldp route config  mode=create   handle=${ldpRouterPE}   fec_type=prefix  fec_ip_prefix_length=24   fec_ip_prefix_start=120.1.1.1   num_lsps=1

    ${status} =  Get From Dictionary  ${device_cfg_ret0_route0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nFailed to create LDP prefix on PE\n${device_cfg_ret0_route0}
    ...  ELSE  Log To Console  \n*****Create LDP prefix on PE successfully

##############################################################
# Step12.Start LDP router
##############################################################

    Log To Console  Start LDP router

    ${ctrl_ret2} =  emulation ldp control  handle=${ldpRouterPE}   mode=start

    ${status} =  Get From Dictionary  ${ctrl_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nStart LDP router on PE router failed\n${ctrl_ret2}
    ...  ELSE  Log To Console  \n***** Start LDP router on PE successfully

##############################################################
# Step13.Configure MPLS L3VPN PE on port2
##############################################################

    Log To Console  Configure PE router
     
    ${device_ret0} =  emulation mpls l3vpn pe config  mode=enable   port_handle=${port1}   enable_p_router=0
    ...  igp_session_handle=${ospfRouterPE}   bgp_session_handle=${bgpRouterPE}   mpls_session_handle=${ldpRouterPE}   pe_count=1

    ${status} =  Get From Dictionary  ${device_ret0}  status
    Run Keyword If  ${status} == 0  Log To Console  \nCreate PE router failed\n${device_ret0}
    ...  ELSE  Log To Console  \n***** Create PE router successfully

    ${vpnRouterPE} =  Get From Dictionary  ${device_ret0}  handle

##############################################################
# Step14.Create MPLS L3VPN CE on port1 
##############################################################

    Log To Console  Create MPLS CE on left side

    ${device_ret1} =  emulation mpls l3vpn site config  mode=create   ce_session_handle=${bgpRouterCE}   vpn_id=100   pe_loopback_ip_prefix=32   pe_loopback_ip_addr=220.1.1.1   rd_start=123:1   port_handle=${port1}   interface_ip_addr=13.31.0.11   interface_ip_prefix=16   site_count=1

    ${status} =  Get From Dictionary  ${device_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nFailed to create MPLS CE on left side\n${device_ret1}
    ...  ELSE  Log To Console  \n***** Create CE on left side successfully

    ${ceCustomSide} =  Get From Dictionary  ${device_ret1}  handle

##############################################################
# Step15.Create MPLS L3VPN CE on port2
##############################################################

    Log To Console  Create MPLS CE on right side

    ${device_ret2} =  emulation mpls l3vpn site config  mode=create   ce_session_handle=${vpnRouterPE}   vpn_id=1   pe_loopback_ip_prefix=32   pe_loopback_ip_addr=2.2.2.4   rd_start=123:1   port_handle=${port2}   interface_ip_addr=120.1.1.11   interface_ip_prefix=24  site_count=1

    ${status} =  Get From Dictionary  ${device_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nFailed to create CE on port2\n${device_ret2}
    ...  ELSE  Log To Console  \n*****Create CE on right side successfully

    ${ceProvideSide} =  Get From Dictionary  ${device_ret2}  handle

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
# Step16.Create MPLS L3VPN traffic
##############################################################

    Log To Console  Create traffic from left CE to right CE

    ${streamblock_ret1} =  traffic config  mode=create   port_handle=${port1}   length_mode=fixed   rate_pps=10   
    ...  l3_length=256   emulation_src_handle=${ceCustomSide}   emulation_dst_handle=${ceProvideSide}

    ${status} =  Get From Dictionary  ${streamblock_ret1}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock_ret1}
    ...  ELSE  Log To Console  \n***** run traffic config successfully

    Log To Console  Create traffic from right CE to left CE

    ${streamblock_ret2} =  traffic config  mode=create   port_handle=${port2}   length_mode=fixed   rate_pps=10   
    ...  l3_length=256   emulation_dst_handle=${ceCustomSide}   emulation_src_handle=${ceProvideSide}

    ${status} =  Get From Dictionary  ${streamblock_ret2}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic config failed\n${streamblock_ret2}
    ...  ELSE  Log To Console  \n***** run traffic config successfully

#config part is finished

##############################################################
# Step17.Start catpure and start traffic
##############################################################

    Log To Console  \nStart to capture

    ${packet_control} =  packet control  port_handle=all  action=start

    ${status} =  Get From Dictionary  ${packet_control}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun packet control failed\n${packet_control}
    ...  ELSE  Log To Console  \n***** run packet control successfully
    
    Log To Console  \nStart traffic on port1 and port2

    ${traffic_ctrl_ret} =  traffic control  port_handle=${port1} ${port2}   action=run

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

    Sleep  10s
 
##############################################################
# Step18.Stop traffic and stop catpure
############################################################## 

    Log To Console  \nStop traffic on port1 and port2

    ${traffic_ctrl_ret} =  traffic control  port_handle=${port1} ${port2}   action=stop

    ${status} =  Get From Dictionary  ${traffic_ctrl_ret}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun traffic control failed\n${traffic_ctrl_ret}
    ...  ELSE  Log To Console  \n***** run traffic control successfully

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
# Step19.Get traffic statistics
##############################################################

    Log To Console  Get traffic statistics of port2

    ${port2_stats} =  interface stats  port_handle=${port2}

    ${status} =  Get From Dictionary  ${port2_stats}  status
    Run Keyword If  ${status} == 0  Log To Console  \nGet interface stats failed\n${port2_stats}
    ...  ELSE  Log To Console  \n***** Get interface stats successfully , and results is:\n${port2_stats}

    Log To Console  Get traffic statistics of port1

    ${port1_stats} =  interface stats  port_handle=${port1}

    ${status} =  Get From Dictionary  ${port1_stats}  status
    Run Keyword If  ${status} == 0  Log To Console  \nGet interface stats failed\n${port1_stats}
    ...  ELSE  Log To Console  \n***** Get interface stats successfully , and results is:\n${port1_stats}

##############################################################
# Step20. Release resources
##############################################################

    ${cleanup_sta} =  cleanup session  port_handle=${port1} ${port2}   clean_dbfile=1

    ${status} =  Get From Dictionary  ${cleanup_sta}  status
    Run Keyword If  ${status} == 0  Log To Console  \nrun cleanup session failed\n${cleanup_sta}
    ...  ELSE  Log To Console  \n***** run cleanup session successfully

    
    Log To Console  \n**************Finish***************


