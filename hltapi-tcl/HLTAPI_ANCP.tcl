#########################################################################################################################################################
#Name: HLTAPI_Ancp_Function.tcl
#Author: Fei Cheng
#History: HLTAPI ANCP Function Test  2009/03/17
#
#
#Topology:
#
#                 Dhcp host1    ANCP Router1 1/1        13/25 ANCP 13/26          1/2 Ancp Router2        Dhcp host2
#                [subscriber]-----[STC]--------+-----------[DUT]----------+----------[STC]---------------[subscriber]
#                  .            192.168.4.2  |    192.168.4.1/24     13.210.0.1/24    |13.210.0.2/24  .
#                  .                |                      vlan 1001               vlan 1001                             |                  .
#                  <---------------------------------traffic-------------------------------------------------->.                                .
#                                                    


#Modify History: 
#########################################################################################################################################################

# Run sample:
#            c:>tclsh HLTAPI_Ancp.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_Ancp.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

puts "Load HLTAPI package";
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
set port_list "$port1 $port2";

set iStatus 0;
set streamID 0;

set ip_stc_CE1 172.168.1.2
set ip_stc_PE2 92.168.1.1
set ip_CE1_stc 172.168.1.1
set ip_PE2_stc 92.168.1.2

::sth::test_config  -logfile hltLogfile \
                    -log 1\
                    -vendorlogfile stcExport\
                    -vendorlog 1\
                    -hltlog 1\
                    -hltlogfile hltExport\
                    -hlt2stcmappingfile hlt2StcMapping \
                    -hlt2stcmapping 1\
                    -log_level 7

stc::config automationoptions -logTo  ancpsamp.txt -logLevel INFO

puts "Connect to the chassis";
set ret [sth::connect -device $device_list -port_list $port_list];

set status [keylget ret status]
if {$status} {
    set port1 [keylget ret port_handle.$device1.$port1]
    set port2 [keylget ret port_handle.$device2.$port2]
}

##interface config...
set ret  [sth::interface_config -port_handle $port1 \
                                    -mode config \
                                    -phy_mode copper \
                                    -intf_ip_addr 10.10.10.20 \
                                    -gateway 10.10.10.10 \
                                    -autonegotiation 1 \
                                    -autonegotiation_role_enable 0 \
                                    -autonegotiation_role master \
                                    -arp_send_req 1 ]

set ret  [sth::interface_config -port_handle $port2 \
                                    -mode config \
                                    -phy_mode copper \
                                    -intf_ip_addr 10.10.10.10 \
                                    -gateway 10.10.10.20 \
                                    -autonegotiation 1 \
                                    -autonegotiation_role_enable 1 \
                                    -autonegotiation_role slave \
                                    -arp_send_req 1 ]

puts "Create Ancp router";
set ret [sth::emulation_ancp_config -mode create \
                                    -port_handle $port1 \
                                    -local_mac_addr 00:10:94:A0:00:02 \
                                    -local_mac_step 00:00:00:00:00:01 \
                                    -intf_ip_addr 192.168.4.2 \
                                    -intf_ip_step 0.0.0.1 \
                                    -gateway_ip_addr 192.168.4.1 \
                                    -sut_ip_addr 192.168.4.1 \
                                    -keep_alive 10 \
                                    -ancp_standard "ietf-ancp-protocol2"]

puts "ret of ancp config for router1: $ret \n\n"
set status [keylget ret status]
if {$status} {
    set anRouter1 [keylget ret handle]
}

#create a AN device as AN host on port1... 
set ret [sth::emulation_ancp_config -mode create \
                                    -port_handle $port1 \
                                    -local_mac_addr 00:10:94:CC:00:02 \
                                    -intf_ip_addr 192.168.4.2 \
                                    -intf_ip_step 0.0.0.1 \
                                    -gateway_ip_addr 192.168.4.1 \
                                    -sut_ip_addr 192.168.4.1 \
                                    -keep_alive 10 \
                                    -ancp_standard "rfc_6320" \
                                    -partition_type "FIXED_PARTITION_REQUEST" \
                                    -partition_flag "RECOVERED_ADJACENCY" \
                                    -partition_id 22 \
                                    -code 33 ]

puts "ret of config for AN host: $ret \n\n"
set status [keylget ret status]
if {$status} {
    set anHost1 [keylget ret handle]
}

set ret [sth::emulation_ancp_config -mode create \
                                    -port_handle $port2 \
                                    -local_mac_addr "00:10:94:A1:00:02" \
                                    -local_mac_step 00:00:00:00:00:01 \
                                    -vlan_id 1001 \
                                    -intf_ip_addr 13.210.0.2 \
                                    -intf_ip_step 0.0.0.1 \
                                    -gateway_ip_addr 13.210.0.1 \
                                    -sut_ip_addr 13.210.0.1 \
                                    -keep_alive 10 \
                                    -ancp_standard "ietf-ancp-protocol2"]

puts "ret of ancp config for router2: $ret \n\n"
set status [keylget ret status]
if {$status} {
    set anRouter2 [keylget ret handle]
}

#create a AN device as AN host on port2... 
set ret [sth::emulation_ancp_config -mode create \
                                    -port_handle $port2 \
                                    -local_mac_addr 00:10:94:CC:00:02 \
                                     -intf_ip_addr 13.210.0.2 \
                                    -gateway_ip_addr 13.210.0.1 \
                                    -sut_ip_addr 13.210.0.1 \
                                    -keep_alive 10 \
                                    -ancp_standard "gsmp-l2control-config2"]

puts "ret of config for AN host: $ret \n\n"
set status [keylget ret status]
if {$status} {
    set anHost2 [keylget ret handle]
}

puts "Create Ancp subscribers";
set ret2 [sth::emulation_ancp_subscriber_lines_config -mode create \
                                   -ancp_client_handle $anRouter1 \
                                   -handle $anHost1 \
                                   -subscriber_lines_per_access_node 1 \
                                   -circuit_id "test" \
                                   -remote_id "cf" \
                                   -circuit_id_suffix 2 \
                                   -circuit_id_suffix_step 1 \
                                   -circuit_id_suffix_repeat 2 \
                                   -include_encap 1 \
                                   -data_link "ethernet" \
                                   -dsl_type "adsl2" \
                                   -actual_rate_upstream "444" \
                                   -upstream_min_rate "22" \
                                   -actual_rate_downstream "555"]

puts "ret of ancp subscriber config for host 1 : $ret2 \n\n"

set status [keylget ret2 status]
if {$status} {
    set anHost1 [keylget ret2 handle]
}

set ret2 [sth::emulation_ancp_subscriber_lines_config -mode create \
                                   -ancp_client_handle $anRouter2 \
                                   -subscriber_lines_per_access_node 1 \
                                   -handle $anHost2 \
                                   -circuit_id "test"  \
                                   -circuit_id_suffix 2 \
                                   -circuit_id_suffix_step 1 \
                                   -circuit_id_suffix_repeat 2 \
                                   -remote_id "cf" \
                                   -remote_id_suffix 3 \
                                   -remote_id_suffix_step 2 \
                                   -remote_id_suffix_repeat 3 \
                                   -tlv_service_vlan_id "@v(1)" \
                                   -tlv_service_vlan_id_wildcard 1 \
                                   -tlv_customer_vlan_id "@x(1,1,1,0,2)" \
                                   -tlv_customer_vlan_id_wildcard 1 \
                                   -vlan_allocation_model "1_1" \
                                   -enable_c_vlan 1 \
                                   -customer_vlan_id 1001 \
                                   -include_encap 1 \
                                   -data_link "ethernet" \
                                   -dsl_type "adsl2" \
                                   -actual_rate_upstream "444" \
                                   -upstream_min_rate "22" \
                                   -actual_rate_downstream "555"]

#change the filename to your local dir                                 
stc::perform SaveasXml -config system1 -filename "./ancptest.xml"
set comp [regression::check_config [info script]]

puts "ret of ancp subscriber config for host 2 : $ret2 \n\n"
puts ">>>>>>>>>>>>>>>I AM HERE<<<<<<<<<<<<<<<<<"
set status [keylget ret2 status]
if {$status} {
    set anHost2 [keylget ret2 handle]
}


puts ">>>>>>>>>>>>>>ANY LUCK?<<<<<<<<<<<<<<<<<<"

puts "Start ANCP devices and subscribers...";
set cRet [sth::emulation_ancp_control -ancp_handle $anRouter1 -ancp_subscriber $anHost1 -action initiate \
                                      -action_control start]

after 3000
puts "start ancp router1: $cRet \n\n"

puts "Start flap subscribers...";
set cRet [sth::emulation_ancp_control -ancp_subscriber $anHost1 -action flap_start -action_control start]

after 5000

puts "stop flap subscribers...";
set cRet [sth::emulation_ancp_control -ancp_subscriber $anHost1 -action flap_stop -action_control start]

puts "flap subscribers 2 times...";
set cRet [sth::emulation_ancp_control -ancp_subscriber $anHost2 -action flap -flap_count 2 -action_control start]

puts "Get ANCP results...";
set sRet [sth::emulation_ancp_stats -handle $anRouter1]
puts "$sRet \n\n"

set sRet [sth::emulation_ancp_stats -handle $anRouter1 -reset 1]
puts "$sRet \n\n"

puts "Create traffic...";
set ret [sth::traffic_config -mode create \
                             -port_handle $port1 \
                             -transmit_mode continuous \
                             -rate_pps 1000 \
                             -emulation_src_handle $anHost1 \
                             -emulation_dst_handle $anHost2]

set ret [sth::traffic_config -mode create \
                             -port_handle $port2 \
                             -transmit_mode continuous \
                             -rate_pps 1000 \
                            -emulation_src_handle $anHost2 \
                             -emulation_dst_handle $anHost1]

puts "Start the traffic..."
sth::traffic_control -action run -port_handle $port1
sth::traffic_control -action run -port_handle $port2

# Wait 3 seconds
puts "Wait for 3 seconds..."
after 300

puts "get the traffic results..."
set trafficStats [sth::traffic_stats -mode aggregate -port_handle $port1]

puts "$trafficStats \n\n"

set trafficStats [sth::traffic_stats -mode aggregate -port_handle $port2]

puts "$trafficStats \n\n"

puts "_SAMPLE_SCRIPT_SUCCESS"

exit;























