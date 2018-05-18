#################################################################################################
# Title         :       HLTAPI_EOAM_topopology_itut_y1731_vlan.tcl                              #
# Purpose       :       To verify the EOAM command can work #
# TestCase      :     	P2.40_Spirent_TestCenter/HLTAPI/EOAM/HLTAPI_EOAM_msg_itut_y1731_vlan                                                                                  #
# Summary       :       This script creates a simple two ports (2 ports) EOAM config.           #
#                       																		#
#                                                                                               #
# Attributes Tested:  ::sth::emulation_oam_config_msg                                           #
#                           port_handle, -top_type, mac_local, mac_local_incr_mode, ttl,        #
#                           md_level, tlv_sender_length , tlv_sender_chassis_id_subtype,        #
#                                                                                               #
# Config        :       Two Ethernet ports connected to back to back
#                                                                                               #
# Note          :                                                                               #
#                                                                                               #
# Software Req  :   2.40 HLTAPI package                                                         #
# Est. Time Req :                                                                               #
#                                                                                               #
# Pass/Fail Criteria:  Script fails if: 1) Any command returns an error                         #
#                                       2) Can not get the info of EOAM                         #
#                                                                                               #
#                                                                                               #
# Revison History  :                                                                            #
#             Created: - Vicky 03/11/08                                                 	    #
#                                                                                               #
# Test Type: Sanity, Acceptance, Regression                                                     #
#                                                                                               #
# Run:                                                                                          #
#            c:>tclsh HLTAPI_EOAM_topopology_itut_y1731_vlan.tcl 10.61.44.2 3/1 3/3                            #
#                                                                                               #
#                                                                                               #
#  "Copyright Spirent Communications PLC, All rights reserved"                                  #
#                                                                                               #
#################################################################################################

# Run sample:
#            c:>tclsh HLTAPI_EOAM_topology_itut_y1731_vlan.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_EOAM_topology_itut_y1731_vlan.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

package require SpirentHltApi

set device_list      [lindex $argv 0]
set port1        [lindex $argv 1]
set port2        [lindex $argv 2]
set i 1
foreach device $device_list {
    set device$i $device
    incr i
}
set device$i $device
set portlist "$port1 $port2"

set oamStandard "itut_y1731"
set dstAddrType "unicast"
set transmitMode "continuous"
set topTypeList "test"
set topTypeList "loopback linktrace test"
set timeout 15
set vlanOuterId1 1000
set vlanOuterId2 1000
set vlanId1 100
set vlanId2 100
# Define output
set passFail PASS
set scriptLog "HLTAPI_EOAM_Basic_Stats.log"
set helperFile ""

set helperFile ""
set logValue 7
set capture 0

set media "fiber"
set speed "ether100"
set passFail pass
set hPortlist ""

set chassis [::sth::connect -device $device_list -port_list $portlist];
puts "connect to the chassis"
puts $chassis
if {[keylget chassis status] == 1} {
	puts "Pass "
} else {
	puts "Fail "
	set passFail FAIL
	return
}


set p1 [keylget chassis port_handle.$device1.$port1]
set p2 [keylget chassis port_handle.$device2.$port2]


puts "#####################create topType top######################"    

set top1 [::sth::emulation_oam_config_topology -mode create \
                                            -port_handle $p1 \
                                            -count 1 \
                                            -mip_count 2 \
                                            -mep_count 2 \
                                            -vlan_outer_id $vlanOuterId1 \
                                            -vlan_outer_ether_type 0x8100 \
                                            -vlan_id $vlanId1 \
                                            -vlan_ether_type 0x9200  \
                                            -oam_standard $oamStandard \
                                            -mac_local 00:94:01:00:02:01 \
                                            -mac_local_incr_mode increment \
                                            -mac_local_step 00:00:00:00:00:01 \
                                            -mac_remote 00:94:01:10:01:01 \
                                            -mac_remote_incr_mode increment \
                                            -mac_remote_step 00:00:00:00:00:01 \
                                            -sut_ip_address 192.168.1.1 \
                                            -responder_loopback 1 \
                                            -responder_link_trace 1 \
                                            -continuity_check 1 \
                                            -continuity_check_interval 100ms \
                                            -continuity_check_mcast_mac_dst 1 \
                                            -continuity_check_burst_size 3 \
                                            -md_level 2 \
                                            -md_name_format icc_based \
                                            -md_integer 4 \
                                            -short_ma_name_format char_str \
                                            -short_ma_name_value Sh_MA_ \
                                            -md_mac 00:94:01:00:02:00 \
                                             -mep_id 1 \
                                            -mep_id_incr_mode increment \
                                            -mep_id_step 1 ]




                                            
if {[keylget top1 status] == 1} {
	puts "Pass "
} else {
	puts "Fail "
	set passFail FAIL
	return
}
puts "config the EOAM on port1"

#####################config port 2###############33
set top2  [::sth::emulation_oam_config_topology -mode create \
                                            -port_handle $p2 \
                                            -count 1 \
                                            -mip_count 2 \
                                            -mep_count 2 \
                                            -mac_local 00:94:01:10:01:01 \
                                            -mac_local_incr_mode increment \
                                            -mac_local_step 00:00:00:00:00:01 \
                                            -mac_remote 00:94:01:00:02:01  \
                                            -mac_remote_incr_mode increment \
                                            -mac_remote_step 00:00:00:00:00:01 \
                                            -oam_standard $oamStandard \
                                            -vlan_outer_id $vlanOuterId1 \
                                            -vlan_outer_ether_type 0x8100 \
                                            -vlan_id $vlanId1 \
                                            -vlan_ether_type 0x9200  \
                                            -sut_ip_address 192.168.1.1 \
                                            -responder_loopback 1 \
                                            -responder_link_trace 1 \
                                            -continuity_check 1 \
                                            -continuity_check_interval 100ms \
                                            -continuity_check_mcast_mac_dst  1\
                                            -continuity_check_burst_size 3 \
                                             -md_name_format icc_based \
                                            -md_level 2 \
                                            -md_integer 4 \
                                            -short_ma_name_format char_str \
                                            -short_ma_name_value Sh_MA_ \
                                            -md_mac 00:94:01:00:03:00 \
                                            -mep_id 4 \
                                            -mep_id_incr_mode increment \
                                            -mep_id_step 1]

                                  #          -md_name_format mac_addr \
                                            
 
                          
  if {[keylget top2 status] == 1} {
	puts "Pass "
} else {
	puts "Fail "
	set passFail FAIL
	return
}
puts "config the EOAM on port2"

#config parts are finished

puts $top1
set topHandleList1 [keylget top1 handle]
set topHandleList2 [keylget top2 handle]
set top1_0 [lindex [keylget top1 handle] 0]
set top1_1 [lindex [keylget top1 handle] 1]
set top1_2 [lindex [keylget top1 handle] 2]
set top1_3 [lindex [keylget top1 handle] 3]

lappend toplist $topHandleList1
lappend toplist $topHandleList2
puts  "##################begin to start EOAM########################"
set cmdReturn [::sth::emulation_oam_control -action start \
										-handle $topHandleList2]

if {[keylget cmdReturn status] == 1} {
	puts "Pass "
} else {
	puts "Fail "
	set passFail FAIL
	return
}
             
puts "#######################EOAM is start ##################"
stc::sleep 10
puts  "##################begin to stop  EOAM########################"

     set cmdReturn [::sth::emulation_oam_control -action stop \
                                                -handle $topHandleList2]


if {[keylget cmdReturn status] == 1} {
	puts "Pass "
} else {
	puts "Fail "
	set passFail FAIL
	return
}

puts "#######################EOAM is stoped ##################"


puts "Start to get the info of ports"


set statsReturn [::sth::emulation_oam_info -mode aggregate \
                                              -port_handle $p1]
puts $statsReturn
                                              
if {[keylget statsReturn status] == 1} {
	puts "Pass "
} else {
	puts "Fail "
	set passFail FAIL
	return
}
  

set statsReturn [::sth::emulation_oam_info -mode aggregate \
                                         -port_handle $p2]

                                         
puts $statsReturn

   
if {[keylget statsReturn status] == 1} {
	puts "Pass "
} else {
	puts "Fail "
	set passFail FAIL
	return
}
set cmdReturn [::sth::emulation_oam_control -action reset \
                                        -handle $topHandleList1]

if {[keylget cmdReturn status] == 1} {
	puts "Pass "
} else {
	puts "Fail "
	set passFail FAIL
	return
}


#########################modify  the EOAM config##################
set top3 [::sth::emulation_oam_config_topology -mode modify \
                                            -handle $top1_0 \
                                            -count 1 \
                                            -mip_count 2 \
                                            -mep_count 2 \
                                            -mac_local 00:94:01:00:02:01 \
                                            -mac_local_incr_mode increment \
                                            -mac_local_step 00:00:00:00:00:01 \
                                            -mac_remote 00:94:01:10:01:01 \
                                            -mac_remote_incr_mode increment \
                                            -mac_remote_step 00:00:00:00:00:01 \
                                            -sut_ip_address 192.168.1.1 \
                                            -vlan_outer_id $vlanOuterId1 \
											-vlan_outer_ether_type 0x8100 \
                                            -vlan_id $vlanId1 \
											-vlan_ether_type 0x9200  \
                                            -responder_loopback 1 \
                                            -responder_link_trace 1 \
                                            -continuity_check 1 \
                                            -continuity_check_interval 1s \
                                            -continuity_check_mcast_mac_dst 1 \
                                            -continuity_check_burst_size 4 \
                                            -md_level 3 \
                                            -md_name_format mac_addr \
                                            -md_integer 4 \
                                            -short_ma_name_format char_str \
                                            -short_ma_name_value Sh_MA_ \
                                            -md_mac 00:94:01:00:03:00 \
                                             -mep_id 10 \
                                            -mep_id_incr_mode increment \
                                            -mep_id_step 1 ]

puts $top3

set topHandleList3 [keylget top1 handle]
set topHandleList2 [keylget top2 handle]
set top3_0 [lindex [keylget top1 handle] 0]
set top3_1 [lindex [keylget top1 handle] 1]
set top3_2 [lindex [keylget top1 handle] 2]
set top3_3 [lindex [keylget top1 handle] 3]
  
lappend toplist $topHandleList3
lappend toplist $topHandleList2

puts  "##################begin to start EOAM########################"
set cmdReturn [::sth::emulation_oam_control -action start \
                                                -handle $topHandleList2]

if {[keylget cmdReturn status] == 1} {
	puts "Pass "
} else {
	puts "Fail "
	set passFail FAIL
	return
}
             

puts "#######################EOAM is start ##################"
stc::sleep 10
puts  "##################begin to stop  EOAM########################"

set cmdReturn [::sth::emulation_oam_control -action stop \
                                                -handle $topHandleList2]


if {[keylget cmdReturn status] == 1} {
	puts "Pass "
} else {
	puts "Fail "
	set passFail FAIL
	return
}

puts "#######################EOAM is stoped ##################"


puts "Start to get the info of ports"

set statsReturn1 [::sth::emulation_oam_info -mode aggregate \
                                              -port_handle $p1]
puts $statsReturn1
                                              
if {[keylget statsReturn1 status] == 1} {
	puts "Pass "
} else {
	puts "Fail "
	set passFail FAIL
	return
}
  

set statsReturn2 [::sth::emulation_oam_info -mode aggregate \
                                         -port_handle $p2]

                                         
puts $statsReturn2

   
if {[keylget statsReturn2 status] == 1} {
	puts "Pass "
} else {
	puts "Fail "
	set passFail FAIL
	return
}
set cmdReturn [::sth::emulation_oam_control -action reset \
                                        -handle $topHandleList1]

if {[keylget cmdReturn status] == 1} {
	puts "Pass "
} else {
	puts "Fail "
	set passFail FAIL
	return
}
set txfm1 [keylget statsReturn2 aggregate]
set txfm2 [keylget txfm1 tx]
set txfm3 [keylget txfm2 fm_pkts]

set rxfm1 [keylget statsReturn1 aggregate]
set rxfm2 [keylget rxfm1 rx]
set rxfm3 [keylget rxfm2 fm_pkts]

puts $txfm3
puts $rxfm3
if {$rxfm3 <[expr $txfm3*0.998]} {
	puts "Fail"
	set passFail FAIL
	return
} else {
	puts "pass"
}

###################################
###  Delete configuration for the ports
###  
###################################
puts "**************  Deleting the ports  **************"

sth::cleanup_session -port_handle $p1

sth::cleanup_session -port_handle $p2

puts "**************  Finished deleting the ports **************"

puts "************** Test Complete **************"
puts $passFail
puts "_SAMPLE_SCRIPT_SUCCESS"

    
