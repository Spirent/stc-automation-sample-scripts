# Copyright (c) 2007 by Spirent Communications, Inc.
# All Rights Reserved
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
# File Name:                 HLTAPI_Bgp_Optimization.tcl
#
# Description:               This script demonstrates how to use the cmd test_control to make the configuration run faster
#################################

# Run sample:
#            c:>tclsh HLTAPI_Bgp_Optimization.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_Bgp_Optimization.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

package require SpirentHltApi

# Setup global variables
set device_list      [lindex $argv 0]
set port1        [lindex $argv 1]
set port2        [lindex $argv 2]
set port_list "$port1 $port2"
set i 1
foreach device $device_list {
    set device$i $device
    incr i
}
set device$i $device

::sth::test_config  -logfile toshltLogfile \
                    -log 1\
                    -vendorlogfile tosstcExport\
                    -vendorlog 1\
                    -hltlog 1\
                    -hltlogfile toshltExport\
                    -hlt2stcmappingfile toshlt2StcMapping \
                    -hlt2stcmapping 1\
                    -log_level 7

#enable the optimization here. This cmd will disable all the apply action inside each HLTAPI cmd.
sth::test_control -action enable

# Start connect and reserve the ports

# Connect to the chassis, reserve one port.
puts "Connect to the chassis";
set ret [sth::connect -device $device_list -port_list $port_list];

set status [keylget ret status]
if {$status} {
    set port1 [keylget ret port_handle.$device1.$port1]
    set port2 [keylget ret port_handle.$device2.$port2]
} else {
    set passFail FAIL
    puts "Error retrieving the port handles, error message was $ret"
	return
}

#create 500 bgp routers
set a [sth::emulation_bgp_config -mode enable \
       -port_handle port2 \
       -active_connect_enable 1  \
       -count 500  \
       -hold_time 300  \
       -local_as 64001  \
       -local_as_mode increment  \
       -local_as_step 1  \
       -remote_as 100  \
       -retries 10  \
       -retry_time 30  \
       -routes_per_msg 2000  \
       -update_interval 30 \
       -vlan_id 501  \
       -vlan_id_mode increment  \
       -vlan_id_step 1 \
       -ip_version 4  \
       -local_ip_addr 22.1.1.2  \
       -remote_ip_addr 22.1.1.1  \
       -next_hop_ip 22.1.1.1  \
       -netmask 16 \
      -local_router_id 22.1.1.2  \
      -local_addr_step 0.0.0.4  \
      -remote_addr_step 0.0.0.4  \
      -ipv4_unicast_nlri 1]

# Add routes for each router
for {set i 0} {$i<500} {incr i} {
	sth::emulation_bgp_route_config -mode add  -handle [lindex [keylget a handles] $i]   -max_route_ranges 1  -num_routes 10  -ip_version 4  -local_pref 0  -prefix_step 1  -as_path as_seq:[expr 64001+$i]  -next_hop_ip_version 4  -next_hop_set_mode same -netmask 255.255.255.252  -prefix 10.1.1.1  -route_ip_addr_step 0.0.0.4 
}

#config parts are finished

#explicitly do the stc apply here
::sth::test_control -action sync
puts "_SAMPLE_SCRIPT_SUCCESS"

exit;







