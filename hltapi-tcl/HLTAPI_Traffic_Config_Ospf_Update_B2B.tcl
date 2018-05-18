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
# File Name:            HLTAPI_Traffic_Config_Ospf_Update_B2B.tcl
#
####################################################################

# Run sample:
#            c:>tclsh HLTAPI_Traffic_Config_Ospf_Update_B2B.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_Traffic_Config_Ospf_Update_B2B "10.61.44.2 10.61.44.7" 3/1 3/3

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
						
set timeout	10
set hPortlist		""

set ipv4AddressList {1.1.1.1 1.1.1.2}
set ipv4GatewayList {1.1.1.2 1.1.1.1}
set ipv6AddressList {1000::1 1000::2}
set ipv6GatewayList {1000::2 1000::1}

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

set RStatus [sth::traffic_config  -mode  create\
            -port_handle      [lindex $hPortlist 0] \
            -l2_encap        ethernet_ii \
	    -l3_protocol     ipv4 \
            -length_mode      fixed\
            -l3_length       512\
	    -l4_protocol ospf ]

keylget RStatus status status
if {!$status} {
    puts $RStatus
    return "  FAILED:  $status"
}
set strHdl [keylget RStatus stream_id]

#OSPFV2: Ospfv2Update
set RStatus [    sth::traffic_config_ospf -mode create\
	    -type packets\
            -ospf_type   update\
            -stream_id $strHdl\
            -ospf_router_id 0.0.0.4\
            -ospf_auth_type password \
            -ospf_auth_value1 2\
            -ospf_router_lsa_num 2\
            -ospf_router_lsa_age "5 6"\
            -ospf_router_lsa_header_options "10000001 10000111"\
            -ospf_router_lsa_num_of_linklist "4 6"\
            -ospf_network_lsa_num 2\
            -ospf_network_lsa_age "5 6"\
            -ospf_network_lsa_header_options "10000001 10000111"\
            -ospf_network_lsa_link_state_id "1.2.3.4 2.3.4.5"\
            -ospf_summary_lsa_num 2\
            -ospf_summary_lsa_age "5 6"\
            -ospf_summary_lsa_header_options "10000001 10000111"\
            -ospf_summary_lsa_ad_router "1.1.1.2 1.1.1.3"\
            -ospf_summary_lsa_reserved "10 12"\
            -ospf_summaryasbr_lsa_num 2\
            -ospf_summaryasbr_lsa_age "5 6"\
            -ospf_summaryasbr_lsa_header_options "10000001 10000111"\
            -ospf_summaryasbr_lsa_type "2 3"\
            -ospf_summaryasbr_lsa_ad_router "1.1.1.2 1.1.1.3"\
            -ospf_summaryasbr_lsa_reserved "10 12"\
            -ospf_asexternal_lsa_num 2\
            -ospf_asexternal_lsa_age "5 6"\
            -ospf_asexternal_lsa_header_options "10000001 10000111"\
            -ospf_asexternal_lsa_ad_router "1.1.1.2 1.1.1.3"\
            -ospf_asexternal_lsa_network_mask "1.1.1.5 1.1.1.6"\
            -ospf_asexternal_lsa_option_ebit "1 0"\
            -ospf_asexternal_lsa_option_reserved "10 11"]
keylget RStatus status status
if {!$status} {
    puts $RStatus
    return "  FAILED:  $status"
}
set ospfHdl [keylget RStatus ospf_handle]
set routerLsaHdl [lindex [keylget RStatus update_router_lsa] 0]
set networkLsaHdl [lindex [keylget RStatus update_network_lsa] 0]
set summaryLsaHdl [lindex [keylget RStatus update_summary_lsa] 0]
set summaryasbrLsaHdl [lindex [keylget RStatus update_summaryasbr_lsa] 0]
set asexternalLsaHdl [lindex [keylget RStatus update_asexternal_lsa] 0]

#create router lsa link for router lsa
#set RStatus [    sth::traffic_config_ospf -mode create\
#	    -stream_id  $strHdl\
#            -type   update_router_lsa_link\
#            -phandle $routerLsaHdl\
#            -ospf_router_lsa_link_num 2\
#            -ospf_router_lsa_link_type "1 4"]

#create tos for summary lsa
set RStatus [    sth::traffic_config_ospf -mode create\
            -stream_id $strHdl\
            -type   update_summary_lsa_tos\
            -phandle $summaryLsaHdl\
            -ospf_summary_lsa_tos_num 3\
            -ospf_summary_lsa_tos_reserved "1 2 3"\
            -ospf_summary_lsa_tos_metric "10 11 12"]
keylget RStatus status status
if {!$status} {
    puts $RStatus
    return "  FAILED:  $status"
}
set tosHdl [lindex [keylget RStatus summary_lsa_tos_handle] 1]

#create tos for summary lsa
set RStatus [    sth::traffic_config_ospf -mode create\
            -stream_id $strHdl\
            -type   update_summary_lsa_tos\
            -phandle $summaryasbrLsaHdl\
            -ospf_summary_lsa_tos_num 3\
            -ospf_summary_lsa_tos_reserved "1 2 3"\
            -ospf_summary_lsa_tos_metric "10 11 12"]
keylget RStatus status status
if {!$status} {
    puts $RStatus
    return "  FAILED:  $status"
}
set AsbrtosHdl [lindex [keylget RStatus summary_lsa_tos_handle] 1]

set RStatus [    sth::traffic_config_ospf -mode create\
            -stream_id $strHdl\
            -type   update_asexternal_lsa_tos\
            -phandle $asexternalLsaHdl\
            -ospf_asexternal_lsa_tos_num 3\
            -ospf_asexternal_lsa_tos_ebit "1 1 0"\
            -ospf_asexternal_lsa_tos_type "0 2 4"\
            -ospf_asexternal_lsa_tos_forwarding_addr "1.1.1.5 1.1.1.6"\
            -ospf_asexternal_lsa_tos_metric "10 11 12"]
keylget RStatus status status
if {!$status} {
    puts $RStatus
    return "  FAILED:  $status"
}
set AsexternaltosHdl [lindex [keylget RStatus asexternal_lsa_tos_handle] 1]

stc::perform SaveasXml -config system1 -filename    "./HLTAPI_l4_ospf_update_asexternal_lsa_create.xml"

set RStatus [    sth::traffic_config_ospf -mode modify\
            -stream_id $strHdl\
	    -type packets\
            -ospf_type   update\
            -handle $ospfHdl\
            -ospf_router_id 0.0.0.5\
            -ospf_auth_type password \
            -ospf_auth_value1 2]
keylget RStatus status status
if {!$status} {
    puts $RStatus
    return "  FAILED:  $status"
}

set RStatus [    sth::traffic_config_ospf -mode modify\
            -stream_id $strHdl\
	    -type packets\
            -ospf_type   update\
            -handle $networkLsaHdl\
            -ospf_network_lsa_network_mask "1.1.1.2"\
            -ospf_network_lsa_link_state_id "1.2.3.5"]
keylget RStatus status status
if {!$status} {
    puts $RStatus
    return "  FAILED:  $status"
}

#modify the summary lsa
set RStatus [    sth::traffic_config_ospf -mode modify\
            -stream_id $strHdl\
	    -type packets\
            -ospf_type   update\
            -handle $summaryLsaHdl\
            -ospf_summary_lsa_network_mask "1.1.1.2"\
            -ospf_summary_lsa_reserved "1"]
keylget RStatus status status
if {!$status} {
    puts $RStatus
    return "  FAILED:  $status"
}

#modify the summaryasbr lsa
set RStatus [    sth::traffic_config_ospf -mode modify\
            -stream_id $strHdl\
	    -type packets\
            -ospf_type   update\
            -handle $summaryasbrLsaHdl\
            -ospf_summary_lsa_network_mask "1.1.1.2"\
            -ospf_summary_lsa_reserved "1"]
keylget RStatus status status
if {!$status} {
    puts $RStatus
    return "  FAILED:  $status"
}

#modify the asexternal lsa
set RStatus [    sth::traffic_config_ospf -mode modify\
            -stream_id $strHdl\
	    -type packets\
            -ospf_type   update\
            -handle $asexternalLsaHdl\
            -ospf_asexternal_lsa_header_options "10000011"\
            -ospf_asexternal_lsa_ad_router "1.1.1.4"\
            -ospf_asexternal_lsa_network_mask "1.1.1.7"\
            -ospf_asexternal_lsa_option_ebit "0"]
keylget RStatus status status
if {!$status} {
    puts $RStatus
    return "  FAILED:  $status"
}

#modify the summary lsa tos field
set RStatus [    sth::traffic_config_ospf -mode modify\
            -stream_id $strHdl\
            -type   update_summary_lsa_tos\
            -handle $tosHdl\
            -ospf_summary_lsa_tos_reserved "15"\
            -ospf_summary_lsa_tos_metric "13"]
keylget RStatus status status
if {!$status} {
    puts $RStatus
    return "  FAILED:  $status"
}

#modify the summaryasbr lsa tos field
set RStatus [    sth::traffic_config_ospf -mode modify\
            -stream_id $strHdl\
            -type   update_summary_lsa_tos\
            -handle $AsbrtosHdl\
            -ospf_summary_lsa_tos_reserved "15"\
            -ospf_summary_lsa_tos_metric "13"]
keylget RStatus status status
if {!$status} {
    puts $RStatus
    return "  FAILED:  $status"
}

#modify the asexternal lsa tos field
set RStatus [    sth::traffic_config_ospf -mode modify\
            -stream_id $strHdl\
            -type   update_asexternal_lsa_tos\
            -handle $AsexternaltosHdl\
            -ospf_asexternal_lsa_tos_ebit "0"\
            -ospf_asexternal_lsa_tos_type "6"\
            -ospf_asexternal_lsa_tos_forwarding_addr "1.1.1.2"]
keylget RStatus status status
if {!$status} {
    puts $RStatus
    return "  FAILED:  $status"
}

stc::perform SaveasXml -config system1 -filename ./HLTAPI_l4_ospf_update_asexternal_lsa_modify.xml
#config parts are finished

#delete the update lsa handle
set RStatus [    sth::traffic_config_ospf -mode delete\
            -stream_id $strHdl\
	        -type packets\
            -ospf_type   update\
            -handle $ospfHdl]
keylget RStatus status status
if {!$status} {
    puts $RStatus
    return "  FAILED:  $status"
}

stc::perform SaveasXml -config system1 -filename    "./HLTAPI_l4_ospf_update_asexternal_lsa_delete.xml"

puts "_SAMPLE_SCRIPT_SUCCESS"
puts "\n test over"

exit