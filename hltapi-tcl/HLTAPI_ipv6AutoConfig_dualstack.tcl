################################################################################
#
# File Name:         HLTAPI_ipv6AutoConfig_dualstack.tcl
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup IPv6 Autoconfiguration Clients test.
#                    In this test, dual stack clients are emulated on STC port and and ipv6 ND on DUT.
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Config ipv6 host
#                    3. Start ipv6 auto configuration
#                    4. Stop ipv6 auto configuration
#                    5  Retrive results
#                    6. Check the status/results
#                    7. Release resources
#
#
# Topology
#                   STC Port1                               DUT                        
#                [Dual Stack Client/Host]------------------[dual stack ND]
#                                              
# DUT configuration [Cisco 7200]:
#
# ip address 192.86.1.1 255.255.255.0
# ipv6 address 2001::1/64
# ipv6 enable
# ipv6 nd prefix 2001::/64
#
################################################################################

# Run sample:
#            c:>tclsh HLTAPI_ipv6AutoConfig_dualstack.tcl 10.61.44.2 3/1

package require SpirentHltApi

set device [lindex $argv 0]
set port1  [lindex $argv 1]

set enableHltLog 1

if {$enableHltLog} {
::sth::test_config  -logfile ipv6AutoConfig_dualstack_hltLogfile \
                    -log 1 \
                    -vendorlogfile ipv6AutoConfig_dualstack_stcExport\
                    -vendorlog 1\
                    -hltlog 1\
                    -hltlogfile ipv6AutoConfig_dualstack_hltExport \
                    -hlt2stcmappingfile ipv6AutoConfig_dualstack_hlt2StcMapping \
                    -hlt2stcmapping 1 \
                    -log_level 7

}

#######################################
#Step1: Reserve and connect chassis ports
#######################################
puts "Reserve and connect chassis ports"
set returnedString [sth::connect -device $device -port_list [list $port1] -offline 0]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}

keylget returnedString port_handle.$device.$port1 hltHostPort

puts "Port List: $hltHostPort"

#########################################
## Step2: Emulate IPv6 hosts
#########################################
puts "emulation_ipv6_autoconfig .....\n"
# Create & configure a hosts for IPv6 auto configuration
set returnedString [ sth::emulation_ipv6_autoconfig  \
                        -mode                           create \
                        -port_handle                    $hltHostPort \
                        -ip_version                     4_6\
                        -count                          5\
                        -local_ip_addr                  10.10.10.10\
                        -local_ip_addr_step             0.0.0.1\
                        -local_ip_prefix_len            24\
                        -gateway_ip_addr                192.86.1.1\
                        -gateway_ip_addr_step           0.0.0.1\
                        -local_ipv6_addr                2001::2\
                        -local_ipv6_addr_step           "0000::1"\
                        -local_ipv6_prefix_len          64\
                        -gateway_ipv6_addr              "2001::1"\
                        -gateway_ipv6_addr_step         "0000::1"\
                        -dad_enable                     true\
                        -dad_transmit_count             3\
                        -dad_retransmit_delay           2000\
                        -router_solicit_retransmit_delay 4000\
                        -router_solicit_retry           4]


keylget returnedString status status
keylget returnedString handle ipv6Handle
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}

puts "Handles: $ipv6Handle"

#Modify hosts for IPv6 auto configuration
set returnedString [ sth::emulation_ipv6_autoconfig  \
                        -mode                           modify \
                        -handle                         $ipv6Handle \
                        -dad_enable                     true\
                        -dad_transmit_count             4\
                        -dad_retransmit_delay           1000\
                        -router_solicit_retransmit_delay 3000\
                        -router_solicit_retry           5]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}

#config parts are finished

#########################################
## Step3: Start IPv6 Auto configuration
#########################################
#Start hosts for IPv6 auto configuration
set returnedString [ sth::emulation_ipv6_autoconfig_control  \
                        -action                         start \
                        -port_handle                    $hltHostPort]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}

set value 50
puts "Wait for $value secs till all the clients are assigned with valid ipv6 addresses...........\n"
set valueInMs [expr $value * 1000]
after $valueInMs

puts "Saved XML....\n"
stc::perform SaveasXml -config system1 -filename    "HLTAPI_ipv6AutoConfig_dual_b4.xml"

#########################################
## Step4: Get Results
#########################################
set returnedString [ sth::emulation_ipv6_autoconfig_stats  \
                        -action                         collect \
                        -port_handle                    $hltHostPort\
                        -mode                           aggregate]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}

keylget returnedString $hltHostPort.state State
keylget returnedString $hltHostPort.tx_rtr_sol TxRS
keylget returnedString $hltHostPort.rx_rtr_adv RxRA

if {$State == "BOUND"} {
    puts "All clients are bounded "
} else {
    puts "  FAILED: Some of the clients not bounded "
	return
}

puts "RS/RA Statistics: <RS: $TxRS> <RA: $RxRA>"

#########################################
## Step5: Stop IPv6 Auto configuration
#########################################
#Stop hosts for IPv6 auto configuration
set returnedString [ sth::emulation_ipv6_autoconfig_control  \
                        -action                         stop \
                        -port_handle                    $hltHostPort]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}

stc::perform SaveasXml -config system1 -filename    "HLTAPI_ipv6AutoConfig_dual.xml"
puts "Saved XML....\n"

########################################
#step6: Release resources
########################################
set returnedString [::sth::cleanup_session -port_list $hltHostPort]

keylget returnedString status status
if {!$status} {
    puts "  FAILED:  $returnedString"
	return
}

puts "_SAMPLE_SCRIPT_SUCCESS"
