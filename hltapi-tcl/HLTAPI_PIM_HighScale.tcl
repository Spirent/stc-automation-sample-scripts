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


# File Name:     HLTAPI_PIM_HighScale.tcl
# Description:   This script demonstrates the use of Spirent HLTAPI PIM with 20K Multicast groups.
#
########################################

# Run sample:
#            c:>tclsh HLTAPI_PIM_HighScale.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_PIM_HighScale.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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

# proc printProperties
proc printProperties {lbl handle} {
   if {![string equal $handle " "]} {
      puts "$lbl Properties:"
      puts "================"
      foreach {a v} [::stc::get $handle] {
         puts "$a:  $v"
      }
   }

   puts ""
}

# PIM params
set pim_up_router_ip_addr_start          "13.13.0.10"
set pim_up_router_nei_ip_addr            "13.13.0.1"
set pim_down_router_ip_addr_start        "13.14.0.10"
set pim_down_router_nei_ip_addr          "13.14.0.1"
set rp_ip_addr                           "1.1.1.4"

# multicast group params
set mcg_up_ip_addr_start          "225.18.0.10"
set mcg_down_ip_addr_start        "225.19.0.10"
set num_multicast_groups           10000

set passFail PASS
set Result ""
set hPortlist ""
set media "copper"
set speed "ether1000"

# Call off the internal apply
::sth::test_control -action enable

# Connect and reserve ports
puts "\nConnecting to the ports..."
set ret [sth::connect -device $device_list -port_list "$port1 $port2"]
set returnedString [keylget ret status]

if {$returnedString} {
    #Retrieve port handles for later use
    set hPort($device1,$port1) [keylget ret port_handle.$device1.$port1]
    set hPortlist [concat $hPortlist $hPort($device1,$port1)]
	
	set hPort($device2,$port2) [keylget ret port_handle.$device2.$port2]
    set hPortlist [concat $hPortlist $hPort($device2,$port2)]
	
    set hltPort2 [lindex $hPortlist 1]
    set hltPort1 [lindex $hPortlist 0]
} else {
    set passFail FAIL
    puts "Error retrieving the port handles, error message was $ret"
    exit
}  ;# end if-else

foreach portHnd $hPortlist {
    puts "Configuring $portHnd with $media - $speed..."
    set ret [sth::interface_config -port_handle $portHnd \
                                              -mode "config" \
                                              -speed $speed \
                                              -intf_mode ethernet \
                                              -phy_mode $media \
                                              -duplex full \
                                              -arp_send_req 0]
     set RStatus [keylget ret status]

}

#1. Configure MC groups
puts "\nCreating FIRST multicast groups for this test"
set ret [sth::emulation_multicast_group_config -ip_addr_start $mcg_up_ip_addr_start \
                                                                 -mode "create" \
                                                                 -num_groups $num_multicast_groups]
set returnedString [keylget ret status]
if {$returnedString} {
    set McGroupHandle(1) [keylget ret handle]
    puts "  Multicast Group Handle:  $McGroupHandle(1)"

} else {
    puts "Error message was $ret"
    set passFail FAIL
    exit
}

puts "\nCreating SECOND multicast groups for this test"
set ret [sth::emulation_multicast_group_config -ip_addr_start $mcg_down_ip_addr_start \
                                                                 -mode "create" \
                                                                 -num_groups $num_multicast_groups]
set returnedString [keylget ret status]
if {$returnedString} {
    set McGroupHandle(2) [keylget ret handle]
    puts "  Multicast Group Handle:  $McGroupHandle(2)"

} else {
    puts "Error message was $ret"
    set passFail FAIL
    exit
}

#2. Setting up the up stream router
puts "\nCreating up stream pim router"
set ret [sth::emulation_pim_config \
                                    -port_handle $hltPort1 \
                                    -mode "create" \
                                    -pim_mode "sm" \
                                    -count 1 \
                                    -ip_version 4 \
                                    -type "c_bsr" \
                                    -router_id $pim_up_router_ip_addr_start \
                                    -router_id_step 0.0.1.0 \
                                    -intf_ip_addr $pim_up_router_ip_addr_start \
                                    -intf_ip_addr_step 0.0.1.0 \
                                    -intf_ip_prefix_len 24 \
                                    -neighbor_intf_ip_addr $pim_up_router_nei_ip_addr \
                                    -c_bsr_rp_addr $rp_ip_addr \
                                    -c_bsr_priority 1 \
                                    -c_bsr_rp_priority 100 \
                                    -c_bsr_rp_holdtime 130 \
                                    -bidir_capable 1 \
                                    -bs_period 160 \
                                    -dr_priority 1 \
                                    -hello_holdtime 140 \
                                    -hello_interval 40 \
                                    -hello_max_delay 50 \
                                    -join_prune_holdtime 240 \
                                    -join_prune_interval 80 \
                                    -override_interval 1000 \
                                    -prune_delay 100\
                                    -prune_delay_enable 1]
set returnedString [keylget ret status]
if {$returnedString} {
    set upStreamRtrList [keylget ret handle]
    puts " Up Stream Router Handle: $upStreamRtrList"

} else {
    puts "Error message was $ret"
    set passFail FAIL
    exit
}

#3. Link the up stream router to multicast group
puts "\nLink the multicast group to pim upstream router"
set ret [sth::emulation_pim_group_config -mode "create" \
                                                           -group_pool_handle $McGroupHandle(1) \
                                                           -session_handle $upStreamRtrList\
                                                           -interval 0 \
                                                           -rate_control 0 \
                                                           -rp_ip_addr $rp_ip_addr \
                                                           -wildcard_group 0]
set returnedString [keylget ret status]
if {$returnedString} {
    set pimGroupMemberHandle(1) [keylget ret handle]
    puts " Up Stream PIM Group Member Handle: $pimGroupMemberHandle(1)"
    printProperties "PIM Group Member 1" $pimGroupMemberHandle(1)

} else {
    puts "Error message was $ret"
    set passFail FAIL
    exit
}

#4. Setting up the down stream router
puts "\nCreating down stream pim router"
set ret [sth::emulation_pim_config \
                                            -port_handle $hltPort2 \
                                            -mode "create" \
                                            -pim_mode "sm" \
                                            -count 1 \
                                            -ip_version 4 \
                                            -router_id $pim_down_router_ip_addr_start \
                                            -router_id_step 0.0.1.0 \
                                            -type "c_bsr" \
                                            -intf_ip_addr $pim_down_router_ip_addr_start \
                                            -intf_ip_addr_step 0.0.1.0 \
                                            -intf_ip_prefix_len 24 \
                                            -neighbor_intf_ip_addr $pim_down_router_nei_ip_addr \
                                            -c_bsr_rp_addr $rp_ip_addr \
                                            -c_bsr_priority 1 \
                                            -c_bsr_rp_priority 10 \
                                            -c_bsr_rp_holdtime 30 \
                                            -bidir_capable 0 \
                                            -bs_period 60 \
                                            -dr_priority 1 \
                                            -hello_holdtime 105 \
                                            -hello_interval 30 \
                                            -hello_max_delay 30 \
                                            -join_prune_holdtime 210 \
                                            -join_prune_interval 60 \
                                            -override_interval 1000 \
                                            -prune_delay 100 \
                                            -prune_delay_enable 1]
set returnedString [keylget ret status]
if {$returnedString} {
    set downStreamRtrList [keylget ret handle]
    puts " Down stream Router Handle: $downStreamRtrList"

} else {
    puts "Error message was $ret"
    set passFail FAIL
    exit
}

#5. Link the down stream router to multicast group
puts "#\nLink the multicast group to pim down stream router"
set ret [sth::emulation_pim_group_config -group_pool_handle $McGroupHandle(2) \
                                                           -interval 0 \
                                                           -mode "create" \
                                                           -rate_control 0 \
                                                           -rp_ip_addr $rp_ip_addr \
                                                           -session_handle $downStreamRtrList \
                                                           -wildcard_group 0]
set returnedString [keylget ret status]
if {$returnedString} {
    set pimGroupMemberHandle(2) [keylget ret handle]
    puts " Down Stream PIM Group Member Handle: $pimGroupMemberHandle(2)"
    printProperties "PIM Group Member 2" $pimGroupMemberHandle(2)

} else {
    puts "Error message was $ret"
    set passFail FAIL
    exit
}

###########
# setting up traffic
puts "\nConfiguring traffic from router to multicast group..."
set ret [sth::traffic_config -mode create \
                                               -port_handle $hltPort1 \
                                               -l2_encap ethernet_ii \
                                               -mac_dst_mode increment \
                                               -mac_discovery_gw 41.1.0.1 \
                                               -mac_src 00.21.00.00.00.21 \
                                               -mac_dst 01:00:5E:00:00:01 \
                                               -length_mode fixed \
                                               -l3_length 128 \
                                               -l3_protocol ipv4 \
                                               -emulation_src_handle $upStreamRtrList \
                                               -emulation_dst_handle $McGroupHandle(2) \
                                               -ip_src_addr $pim_up_router_ip_addr_start \
                                               -ip_dst_addr $mcg_down_ip_addr_start]
set returnedString [keylget ret status]

set ret [sth::traffic_config -mode create \
                                               -port_handle $hltPort2 \
                                               -l2_encap ethernet_ii\
                                               -mac_dst_mode increment \
                                               -mac_discovery_gw 42.1.0.1 \
                                               -mac_src 00.22.00.00.00.22 \
                                               -mac_dst 01:00:5E:00:00:06 \
                                               -length_mode fixed \
                                               -l3_length 128 \
                                               -l3_protocol ipv4 \
                                               -emulation_src_handle $downStreamRtrList \
                                               -emulation_dst_handle $McGroupHandle(1) \
                                               -ip_src_addr $pim_down_router_ip_addr_start \
                                               -ip_dst_addr $mcg_up_ip_addr_start]
set returnedString [keylget ret status]

#config parts are finished

# Apply the configuration
::sth::test_control -action sync

puts "\nStarting traffic..."
set ret [sth::traffic_control -action "run" \
                                                -port_handle $hltPort1]
set returnedString [keylget ret status]
set ret [sth::traffic_control -action "run" \
                                                -port_handle $hltPort2]
set returnedString [keylget ret status]

#6. Start PIM routers
puts "\nStart upstream pim routers"
set ret [sth::emulation_pim_control -mode start \
                                                      -port_handle $hltPort1 \
                                                      -handle $upStreamRtrList ]
set returnedString [keylget ret status]
if {$returnedString} {
    puts "Upstream PIM routers start succesfully "
} else {
    puts "Upstream PIM routers start fails. Error message was $ret"
    set passFail FAIL
    exit
}

puts "\nStart downstream pim routers"
set ret [sth::emulation_pim_control -mode start \
                                                      -port_handle $hltPort2 \
                                                      -handle $downStreamRtrList]
set returnedString [keylget ret status]
if {$returnedString} {
    puts "Downstream PIM routers start succesfully "
} else {
    puts "Downstream PIM routers start fails. Error message was $ret"
    set passFail FAIL
    exit
}


puts "\nPIM routers started. Pausing for 30 seconds for neighbor state"
for {set pauseIndex 1} {$pauseIndex <= 30} {incr pauseIndex} {
    puts -nonewline "."
    stc::sleep 1
    flush stdout
}

puts "\n#####Code to Check DUT#############"

if {0} {
    #7. Obtains the stats from both routers
    foreach rtr $upStreamRtrList {
        puts "\nstats for upstream router $rtr."
        set stats [::sth::emulation_pim_info -handle $rtr]
        puts $stats
    }

    foreach rtr $downStreamRtrList {
        puts "\nstats for downstream router $rtr."
        set stats [::sth::emulation_pim_info -handle $rtr]
        puts $stats
    }


    #8. Send Pim joins to the defined groups
    puts "\nSend joins from upstream pim routers"
    foreach router $upStreamRtrList {
        set ret [sth::emulation_pim_control -mode join \
                                                              -port_handle $hltPort1 \
                                                              -handle $router \
                                                              -group_member_handle $pimGroupMemberHandle(1)]
        set returnedString [keylget ret status]

    }

    puts "\nSend joins from downstream pim routers"
    foreach router $downStreamRtrList {
        set ret [sth::emulation_pim_control -mode join \
                                                              -port_handle $hltPort2 \
                                                              -handle $router \
                                                              -group_member_handle $pimGroupMemberHandle(2)]
        set returnedString [keylget ret status]
    }

    puts "\n#####Code to Check DUT after PIM join#############"


    puts "\nPIM joins sent. Waiting for 60 seconds for multicast traffic."
    for {set pauseIndex 1} {$pauseIndex <= 60} {incr pauseIndex} {
        puts -nonewline "."
        stc::sleep 1
        flush stdout
    }
}

#9. Send Pim prunes to the defined groups
puts "\nSleeping for 2 seconds..."
after 2000

puts "\nSend prunes from upstream pim routers"
foreach router $upStreamRtrList {
    set ret [sth::emulation_pim_control -mode prune \
                                                          -port_handle $hltPort1 \
                                                          -handle $router \
                                                          -group_member_handle $pimGroupMemberHandle(1)]
    set returnedString [keylget ret status]
}

puts "\nSend prunes from downstream pim routers"
foreach router $downStreamRtrList {
    set ret [sth::emulation_pim_control -mode prune \
                                                          -port_handle $hltPort2 \
                                                          -handle $router \
                                                          -group_member_handle $pimGroupMemberHandle(2)]
     set returnedString [keylget ret status]
}

puts "\nSleeping for 2 seconds..."
after 2000

puts "\n##### Code to Check DUT after PIM prune ####"

if {0} {
    #8. Send Pim joins to the defined groups
    puts "\nSend joins from upstream pim routers"
    foreach router $upStreamRtrList {
        set ret [sth::emulation_pim_control -mode join \
                                                              -port_handle $hltPort1 \
                                                              -handle $router \
                                                              -group_member_handle $pimGroupMemberHandle(1)]
        set returnedString [keylget ret status]
    }

    puts "nSend joins from downstream pim routers"
    foreach router $downStreamRtrList {
        set ret [sth::emulation_pim_control -mode join \
                                                              -port_handle $hltPort2 \
                                                              -handle $router \
                                                              -group_member_handle $pimGroupMemberHandle(2)]

         set returnedString [keylget ret status]
    }

    puts "\n#####Code to Check DUT after PIM join#############"

}

puts "\nSleeping for 2 seconds..."
after 2000

#9. Stopping pim routers
puts "\nStopping upstream pim routers"
set ret [sth::emulation_pim_control -mode stop \
                                                      -port_handle $hltPort1 \
                                                      -handle $upStreamRtrList]
set returnedString [keylget ret status]

puts "\nStopping downstream pim routers"
set ret [sth::emulation_pim_control -mode stop \
                                                      -port_handle $hltPort2 \
                                                      -handle $downStreamRtrList ]
set returnedString [keylget ret status]

puts "\nSleeping for 2 seconds..."
after 2000

puts "\n##### Code to Check DUT after stop PIM ####"

if {0} {
    # ReStart PIM routers
    puts "\nRestart upstream pim routers"
    set ret [sth::emulation_pim_control -mode restart \
                                                          -port_handle $hltPort1 \
                                                          -handle $upStreamRtrList ]
    set returnedString [keylget ret status]
    if {$returnedString} {
        puts "PIM restart succesful "
    } else {
        puts "Error message was $ret"
        set passFail FAIL
        exit
    }

    puts "\nRestart downstream pim routers"
    set ret [sth::emulation_pim_control -mode restart \
                                                          -port_handle $hltPort2 \
                                                          -handle $downStreamRtrList ]
    set returnedString [keylget ret status]
    if {$returnedString} {
        puts "PIM restart succesful "
    } else {
        puts "Error message was $ret"
        set passFail FAIL
        exit
    }

    puts "\n#### Code to check DUT after PIM restart ####"

}

puts "\nSleeping for 2 seconds..."
after 2000

puts "\nStopping traffic..."
set returnedString [sth::traffic_control -action "stop" \
                                         -port_handle $hPortlist]

puts "\nDeleting ports"
set ret [ ::sth::cleanup_session -port_list $hPortlist]
set intStatus [keylget ret status]
if {! $intStatus} {
    set passFail FAIL
    puts "Error deleting port $port_list"
    exit
}
if {$passFail == "FAIL"} {
    puts "\nTest FAIL"
	exit
} else {
    puts "\nTest PASS"
}
puts "_SAMPLE_SCRIPT_SUCCESS"
