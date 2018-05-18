#####################################################################
# "Copyright 2008 Spirent Communications, PLC. All rights reserved"
#
# By accessing or executing this software, you agree to be bound 
# by the terms of this agreement.
# 
# Redistribution and use of this software in source and binary forms,
# with or without modification, are permitted provided that the 
# following conditions are met:
#   1.  Redistribution of source code must contain the above copyright 
#       notice, this list of conditions, and the following disclaimer.
#   2.  Redistribution in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer
#       in the documentation and/or other materials provided with the
#       distribution.
#   3.  Neither the name Spirent Communications nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# This software is provided by the copyright holders and contributors 
# [as is] and any express or implied warranties, including, but not 
# limited to, the implied warranties of merchantability and fitness for
# a particular purpose are disclaimed.  In no event shall Spirent
# Communications, Inc. or its contributors be liable for any direct, 
# indirect, incidental, special, exemplary, or consequential damages
# (including, but not limited to: procurement of substitute goods or
# services; loss of use, data, or profits; or business interruption)
# however caused and on any theory of liability, whether in contract, 
# strict liability, or tort (including negligence or otherwise) arising
# in any way out of the use of this software, even if advised of the
# possibility of such damage.
#
# File Name:            HLTAPI_Traffic_Config_Ospf_DBD_B2B.tcl
#
####################################################################

# Run sample:
#            c:>tclsh HLTAPI_Traffic_Config_Ospf_DBD_B2B.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_Traffic_Config_Ospf_DBD_B2B "10.61.44.2 10.61.44.7" 3/1 3/3

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
set port_list "$port1 $port2"

set enableHltLog 1
if {$enableHltLog} {
    ::sth::test_config  -logfile hltLogfile \
                        -log 1\
                        -vendorlogfile stcExport\
                        -vendorlog 1\
                        -hltlog 1\
                        -hltlogfile hltExport\
                        -hlt2stcmappingfile hlt2StcMapping \
                        -hlt2stcmapping 1\
                        -log_level 7
}
						
set timeout			10
set hPortlist		""

set ipv4AddressList {1.1.1.1 1.1.1.2}
set ipv4GatewayList {1.1.1.2 1.1.1.1}
set ipv6AddressList {1000::1 1000::2}
set ipv6GatewayList {1000::2 1000::1}
set i 0
set test_type "dd"
set returnedString [sth::connect -device $device_list -port_list $port_list]

keylget returnedString status status
if {!$status} {
puts $returnedString
    return "  FAILED:  $status"
}

keylget returnedString port_handle.$device2.$port2 hltDstPort
keylget returnedString port_handle.$device1.$port1 hltSrcPort

set hPortlist "$hltSrcPort $hltDstPort"

puts "Interface config"
set i 0
foreach port $hPortlist {
    set returnedString [sth::interface_config	-port_handle       $port\
		                                       		-intf_mode         ethernet                             \
		                                       		-phy_mode          copper                               \
		                                       		-speed             ether10                             \
		                                       		-autonegotiation   0                                    \
		                                       		-mode              config                               \
		                                       		-duplex            full                                 \
													-intf_ip_addr [lindex $ipv4AddressList $i] \
													-gateway [lindex $ipv4GatewayList $i] \
													-ipv6_intf_addr [lindex $ipv6AddressList $i] \
													-ipv6_prefix_length 64 \
													-ipv6_gateway [lindex $ipv6GatewayList $i] ]
    
    keylget returnedString status status
    if {!$status} {
	puts $returnedString
        return "  FAILED:  $returnedString"
    }
    incr i
}

#1.OSPFV2: Ospfv2DatabaseDescription
set RStatus [    sth::traffic_config  -mode  create\
            -port_handle      [lindex $hPortlist 0] \
            -l2_encap        ethernet_ii \
            -l4_protocol ospf]

keylget RStatus status status
if {!$status} {
    puts $RStatus
    return "  FAILED:  $status"
}

set strHdl [keylget RStatus stream_id]

if {$test_type == "dd"} {
    set RStatus [    sth::traffic_config_ospf -mode create\
		-type   packets\
		-ospf_type dd\
		-stream_id $strHdl\
		-ospf_router_id 0.0.0.4\
		-ospf_auth_type password \
		-ospf_auth_value1 2\
		-ospf_interface_mtu 8192\
		-ospf_dd_options "10000000"\
		-ospf_lsa_num 2\
		-ospf_lsa_age "5 6"\
		-ospf_lsa_header_options "10000001"\
		-ospf_ls_type "3 4"\
		-ospf_ls_seq_number "80000002 80000003"]
    set ospfHdl [keylget RStatus ospf_handle]
    set lsaHdlList [keylget RStatus dd_lsa_handle]
    set lsaHdl [lindex $lsaHdlList 0]
    
    
    stc::perform SaveasXml -config system1 -filename    "./HLTAPI_l4_ospf_dd_create.xml"
    
    set RStatus [    sth::traffic_config_ospf -mode modify\
		 -handle $ospfHdl\
		-stream_id $strHdl\
		-type   packets\
		-ospf_type dd\
		-ospf_router_id 0.0.0.5\
		-ospf_auth_type userdefined \
		-ospf_auth_value1 3\
		-ospf_interface_mtu 8191]
    
    set RStatus [    sth::traffic_config_ospf -mode modify\
		-handle $lsaHdl\
		-stream_id $strHdl\
		-type   packets\
		-ospf_type dd\
		-ospf_lsa_age "1"\
		-ospf_lsa_header_options "10000011"\
		-ospf_ls_seq_number "80000010"]
    
    stc::perform SaveasXml -config system1 -filename    "./HLTAPI_l4_ospf_dd_modify.xml"
}

#2. ospfv2 ack
if {$test_type == "ack"} {
    set RStatus [    sth::traffic_config_ospf -mode create\
		-type packets\
		-ospf_type   ack\
		-stream_id  $strHdl\
		-ospf_area_id 0.0.0.4\
		-ospf_auth_type md5 \
		-ospf_auth_value2 2\
		-ospf_lsa_num 2\
		-ospf_lsa_age "5 6"\
		-ospf_lsa_header_options "10000001"\
		-ospf_ls_type "3 4"\
		-ospf_ls_seq_number "80000002 80000003"]
    keylget RStatus status status
    if {!$status} {
	puts $RStatus
	return "  FAILED:  $status"
    }
    
    set ospfHdl [keylget RStatus ospf_handle]
    set lsaHdlList [keylget RStatus ack_lsa_handle]
    set lsaHdl [lindex $lsaHdlList 1]
    
    stc::perform SaveasXml -config system1 -filename    "./HLTAPI_l4_ospf_ack_create.xml"
    
    set RStatus [    sth::traffic_config_ospf -mode modify\
		-stream_id  $strHdl\
		 -handle $ospfHdl\
		-type packets\
		-ospf_type   ack\
		-ospf_router_id 0.0.0.5\
		-ospf_auth_type userdefined \
		-ospf_auth_value1 3]
    keylget RStatus status status
    if {!$status} {
	puts $RStatus
	return "  FAILED:  $status"
    }
    
    
    set RStatus [    sth::traffic_config_ospf -mode modify\
		-stream_id  $strHdl\
		-handle $lsaHdl\
		-type packets\
		-ospf_type   ack\
		-ospf_lsa_age "6"\
		-ospf_lsa_header_options "10000001"\
		-ospf_ls_type "3"\
		-ospf_ls_seq_number "80000001"]
    keylget RStatus status status
    if {!$status} {
	puts $RStatus
	return "  FAILED:  $status"
    }
    
    stc::perform SaveasXml -config system1 -filename    "./HLTAPI_l4_ospf_ack_modify.xml"
}

#Unknown
if {$test_type == "unknown"} {
    set RStatus [    sth::traffic_config_ospf -mode create\
		-type   packets\
		-ospf_type unknown\
		-stream_id $strHdl\
		-ospf_area_id 0.0.0.4\
		-ospf_auth_type md5 \
		-ospf_auth_value2 2]
    set ospfHdl [keylget RStatus ospf_handle]
    set RStatus [    sth::traffic_config_ospf -mode modify\
		-type   packets\
		-ospf_type unknown\
		-stream_id $strHdl\
		-handle $ospfHdl\
		-ospf_area_id 0.0.0.5]
    stc::perform SaveasXml -config system1 -filename    "./HLTAPI_l4_ospf_unknown.xml"
}

#config parts are finished

puts "_SAMPLE_SCRIPT_SUCCESS"
puts "\n test over"

exit