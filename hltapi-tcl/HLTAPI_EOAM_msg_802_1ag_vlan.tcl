#################################################################################################
# Title         :       HLTAPI_EOAM_msg_802.1ag.tcl                                       #
# Purpose       :       To verify the EOAM command can work #
# TestCase      :     P2.40_Spirent_TestCenter/HLTAPI/EOAM/HLTAPI_EOAM_msg_802.1ag                                                                                       #
# Summary       :       This script creates a simple two ports (2 ports) EOAM config.           #
#                       									#
#                                                                                               #
# Attributes Tested:  ::sth::emulation_oam_config_msg                                              #
#                           port_handle, -msg_type, mac_local, mac_local_incr_mode, ttl,             #
#                           md_level, tlv_sender_length , tlv_sender_chassis_id_subtype,         #
#                                                                                               #
# Config        :       Two Ethernet ports connected to back to back
#                                                                                               #
# Note          :                                                                               #
#                                                                                               #
# Software Req  :   2.40 HLTAPI package                                                         #
# Est. Time Req :                                                                               #
#                                                                                               #
# Pass/Fail Criteria:  Script fails if: 1) Any command returns an error                         #
#                                       2) Can not get the info of EOAM    
#                                       
#  Pseudocode:           1.Connect 2 ports B2B 
#                        2.Create EOAM on one port, set oam standard as IEEE_802.1ag 
#                        3.Start the EOAM 4.Get the EOAM info,check result 
#                        4.Modify msgtype config
#                        5.Start the EOAM 
#                        6.Get the EOAM info, Get the EOAM info,check TLV transmitted and received 
#                        7.Reset EOAM 
#                        8.Release ports                                                        #
#                                                                                               #
# Revison History  :                                                                            #
#             Created: - Vicky 15/10/08                                                 	    #
#                                                                                               #
# Test Type: Sanity, Acceptance, Regression, requires DUT                                       #
#                                                                                               #
# Run:                                                                                          #
#            c:>tclsh HLTAPI_EOAM_msg_802.1ag.tcl 10.61.44.2 3/1 3/3                            #
#                                                                                               #
#  "Copyright Spirent Communications PLC, All rights reserved"                                  #
#                                                                                               #
#################################################################################################

# Run sample:
#            c:>tclsh HLTAPI_EOAM_msg_802_lan_vlan.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_EOAM_msg_802_lan_vlan.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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

set oamStandard "ieee_802.1ag"
set dstAddrType "unicast"
set transmitMode "continuous"
set msgTypeList "test"
set msgTypeList "loopback linktrace test"
set timeout 15
set vlanOuterId 1000
set vlanId 100
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

::sth::test_config  -logfile hlt_$scriptLog \
					-log 1\
					-vendorlogfile stcExport_$scriptLog\
					-vendorlog 1\
					-hltlog 1\
					-hltlogfile hltExport_$scriptLog\
					-hlt2stcmappingfile hlt2StcMapping_$scriptLog \
					-hlt2stcmapping 1\
					-log_level $logValue

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

puts "#####################create msgType msg######################"    

set msg1 [::sth::emulation_oam_config_msg -mode create \
                                           -port_handle $p1 \
                                           -count 1 \
                                           -dst_addr_type $dstAddrType \
                                           -msg_type loopback   \
                                           -mac_local 00:94:01:00:00:01 \
                                           -mac_local_incr_mode increment \
                                           -mac_local_step 00:00:00:00:00:02 \
                                           -mac_local_repeat 2 \
                                           -mac_remote 00:94:01:00:01:01 \
                                           -mac_remote_incr_mode increment \
                                           -mac_remote_step 00:00:00:00:00:02 \
                                           -mac_remote_repeat 2 \
                                           -oam_standard $oamStandard \
                                           -vlan_outer_id $vlanOuterId \
                                           -vlan_outer_ether_type 0x88A8 \
                                           -vlan_id_outer_step 5 \
                                           -vlan_id $vlanId \
                                           -vlan_ether_type 0x9100 \
                                           -vlan_id_step 5 \
                                           -mac_dst 00:94:01:00:01:01 \
                                           -mac_dst_incr_mode increment \
                                           -mac_dst_step 00:00:00:00:00:02 \
                                           -md_level_incr_mode increment \
                                           -md_level_step 1\
                                           -md_level_repeat 2 \
                                           -trans_id 100 \
                                           -tlv_sender_length 10 \
                                           -tlv_sender_chassis_id 21 \
                                           -tlv_sender_chassis_id_length 10 \
                                           -tlv_sender_chassis_id_subtype 5 \
                                           -tlv_org_length 10 \
                                           -tlv_org_oui 22 \
                                           -tlv_org_subtype 11 \
                                           -tlv_org_value FF \
                                           -tlv_data_length 10\
                                           -tlv_data_pattern 0xAA \
                                           -tlv_user_type 5 \
                                           -tlv_user_length 10 \
                                           -tlv_user_value 0xff \
                                           -tlv_test_length 30 \
                                           -tlv_test_pattern null_with_crc \
                                           -transmit_mode $transmitMode \
                                           -pkts_per_burst 3 \
                                           -rate_pps 5]
if {[keylget msg1 status] == 1} {
	puts "Pass "
} else {
	puts "Fail "
	set passFail FAIL
	return
}

puts "config the EOAM on port1"

set msg2 [::sth::emulation_oam_config_msg -mode create \
                                           -port_handle $p2 \
                                           -count 1 \
                                           -dst_addr_type $dstAddrType \
                                           -msg_type loopback   \
                                           -mac_local 00:94:01:00:01:01 \
                                           -mac_local_incr_mode increment \
                                           -mac_local_step 00:00:00:00:00:02 \
                                           -mac_local_repeat 2 \
                                           -mac_remote 00:94:01:00:00:01 \
                                           -mac_remote_incr_mode increment \
                                           -mac_remote_step 00:00:00:00:00:02 \
                                           -mac_remote_repeat 2 \
                                           -oam_standard $oamStandard \
                                           -vlan_outer_id $vlanOuterId \
                                           -vlan_outer_ether_type 0x88A8 \
                                           -vlan_id_outer_step 5 \
                                           -vlan_id $vlanId \
                                           -vlan_ether_type 0x9100 \
                                           -vlan_id_step 5 \
                                           -mac_dst 00:94:01:00:01:01 \
                                           -mac_dst_incr_mode increment \
                                           -mac_dst_step 00:00:00:00:00:02 \
                                           -md_level_incr_mode increment \
                                           -md_level_step 1\
                                           -md_level_repeat 2 \
                                           -trans_id 100 \
                                           -tlv_sender_length 10 \
                                           -tlv_sender_chassis_id 21 \
                                           -tlv_sender_chassis_id_length 10 \
                                           -tlv_sender_chassis_id_subtype 5 \
                                           -tlv_org_length 10 \
                                           -tlv_org_oui 22 \
                                           -tlv_org_subtype 11 \
                                           -tlv_org_value FF \
                                           -tlv_data_length 10\
                                           -tlv_data_pattern 0xAA \
                                           -tlv_user_type 5 \
                                           -tlv_user_length 10 \
                                           -tlv_user_value 0xff \
                                           -tlv_test_length 30 \
                                           -tlv_test_pattern null_with_crc \
                                           -transmit_mode $transmitMode \
                                           -pkts_per_burst 3 \
                                           -rate_pps 5]

if {[keylget msg2 status] == 1} {
	puts "Pass "
} else {
	puts "Fail "
	set passFail FAIL
	return
}
puts "config the EOAM on port2"
                               
set cmdReturn [stc::perform SaveAsXmlCommand -FileName eoam_stc.xml]
#config parts are finished

puts $msg1
puts $msg2
set msgHandleList1 [keylget msg1 handle]
set msgHandleList2 [keylget msg2 handle]
set msgHandleList "$msgHandleList1,$msgHandleList2"
set msg1_0 [lindex [keylget msg1 handle] 0]
set msg1_1 [lindex [keylget msg1 handle] 1]
set msg1_2 [lindex [keylget msg1 handle] 2]
set msg1_3 [lindex [keylget msg1 handle] 3]

set msg2_0 [lindex [keylget msg2 handle] 0]
set msg2_1 [lindex [keylget msg2 handle] 1]
set msg2_2 [lindex [keylget msg2 handle] 2]
set msg2_3 [lindex [keylget msg2 handle] 3]

puts  "##################begin to start EOAM########################"
set cmdReturn [::sth::emulation_oam_control -action start \
                                                -handle $msgHandleList1]

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
                                                -handle $msgHandleList1]


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
  

#
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
puts "###################get port info############################"

set txfm1 [keylget statsReturn1 aggregate]
set txfm2 [keylget txfm1 tx]
set txfm3 [keylget txfm2 fm_pkts]

set rxfm1 [keylget statsReturn2 aggregate]
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

########################modify the EOAM##############################
set msg3 [::sth::emulation_oam_config_msg -mode modify \
                                           -handle $msg1_0 \
                                           -dst_addr_type $dstAddrType \
                                           -mac_local 00:94:01:00:10:01 \
                                           -mac_remote 00:94:01:10:01:01 \
                                           -vlan_outer_id 2100 \
                                           -vlan_outer_ether_type 0x9100 \
                                           -vlan_id 2200 \
                                           -vlan_ether_type 0x88A8 \
                                           -oam_standard $oamStandard \
                                           -mac_dst 00:94:01:10:01:01 \
                                           -sut_ip_address 13.1.0.1 \
                                           -md_level 3 \
                                           -trans_id 10 \
                                           -tlv_sender_length 10 \
                                           -tlv_sender_chassis_id 21 \
                                           -tlv_sender_chassis_id_length 10 \
                                           -tlv_sender_chassis_id_subtype 5 \
                                           -tlv_org_length 10 \
                                           -tlv_org_oui 22 \
                                           -tlv_org_subtype 11 \
                                           -tlv_org_value FF \
                                           -tlv_data_length 10\
                                           -tlv_data_pattern 0xAA \
                                           -tlv_user_type 5 \
                                           -tlv_user_length 10 \
                                           -tlv_user_value 0xff \
                                           -tlv_test_length 30 \
                                           -tlv_test_pattern null_with_crc \
                                           -transmit_mode $transmitMode \
                                           -pkts_per_burst 4 \
                                           -rate_pps 15]
                                           
set msg4 [::sth::emulation_oam_config_msg -mode modify \
                                           -handle $msg2_0 \
                                           -dst_addr_type $dstAddrType \
                                           -mac_local 00:94:01:10:01:01 \
                                           -mac_remote 00:94:01:00:10:01  \
                                           -vlan_outer_id 2100 \
                                           -vlan_outer_ether_type 0x9100 \
                                           -vlan_id 2200 \
                                           -vlan_ether_type 0x88A8 \
                                           -oam_standard $oamStandard \
                                           -mac_dst 00:94:01:10:01:01 \
                                           -sut_ip_address 13.1.0.1 \
                                           -md_level 3 \
                                           -trans_id 10 \
                                           -tlv_sender_length 10 \
                                           -tlv_sender_chassis_id 21 \
                                           -tlv_sender_chassis_id_length 10 \
                                           -tlv_sender_chassis_id_subtype 5 \
                                           -tlv_org_length 10 \
                                           -tlv_org_oui 22 \
                                           -tlv_org_subtype 11 \
                                           -tlv_org_value FF \
                                           -tlv_data_length 10\
                                           -tlv_data_pattern 0xAA \
                                           -tlv_user_type 5 \
                                           -tlv_user_length 10 \
                                           -tlv_user_value 0xff \
                                           -tlv_test_length 30 \
                                           -tlv_test_pattern null_with_crc \
                                           -transmit_mode $transmitMode \
                                           -pkts_per_burst 4 \
                                           -rate_pps 15]

puts $msg3
set msgHandleList3 [keylget msg3 handle]
set msg3_0 [lindex [keylget msg3 handle] 0]
set msg3_1 [lindex [keylget msg3 handle] 1]
set msg3_2 [lindex [keylget msg3 handle] 2]
set msg3_3 [lindex [keylget msg3 handle] 3]

puts  "##################begin to start EOAM########################"
set cmdReturn [::sth::emulation_oam_control -action start \
                                                -handle $msgHandleList3]

if {[keylget cmdReturn status] == 1} {
	puts "Pass "
} else {
	puts "Fail "
	set passFail FAIL
	return
}
 
puts "#######################EOAM is start ##################"
stc::sleep 20
puts  "##################begin to stop  EOAM########################"

set cmdReturn [::sth::emulation_oam_control -action stop \
                                                -handle $msgHandleList3]


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


#######################Reset the EOAM################################
set cmdReturn [::sth::emulation_oam_control -action reset \
                                        -handle $msgHandleList1]

if {[keylget cmdReturn status] == 1} {
	puts "Pass "
} else {
	puts "Fail "
	set passFail FAIL
	return
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


