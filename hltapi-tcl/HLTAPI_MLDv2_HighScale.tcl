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


# File Name:     HLTAPI_MLDv2_HighScale.tcl
# Description:   This script demonstrates the use of Spirent MLD with 20K Multicast groups.
###############################################################

# Run sample:
#            c:>tclsh HLTAPI_MLDv2_HighScale.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_MLDv2_HighScale.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

package require SpirentHltApi

set device_list      [lindex $argv 0]
set sourcePort        [lindex $argv 1]
set hostPort        [lindex $argv 2]
set i 0
foreach device $device_list {
    set device$i $device
    incr i
}
set device$i $device
set portlist "$sourcePort $hostPort"

# proc checkMLDSessionStats to get MLD info stats
proc checkMLDSessionStats {MLDSessionHandle {mode "join"} {isTraffic "no"}} {

    # MLD info
    puts "\nChecking MLD info for join latencies..."
    set ret [sth::emulation_mld_info -handle $MLDSessionHandle]
    set infoStatus [keylget ret status]
    if {! $infoStatus} {
        puts "Error getting MLD session status"
        puts "Error from command was $ret"
        set ::passFail FAIL
        exit
    } else {
        puts "The command for MLD to get status is $ret"
        set mldJoinInfo [keylget ret group_membership_stats]
        puts "MLD getting status for session $MLDSessionHandle succeeded."
    }   ;# end if-else statement

    array unset joinInfo
    array set joinInfo ""
    MLD_ProcessStats $mldJoinInfo joinInfo retVal $mode $isTraffic
    if {$retVal} {
        set ::passFail FAIL
        puts "ERROR: Not all sessions have ${mode}ed successfully."
        exit
    }

    MLD_CheckState joinInfo
    MLD_DisplayLatencies joinInfo

}


# proc MLD_ProcessStats to check join/leave membership status
proc MLD_ProcessStats {groupMemStats raName rvName checkLatType isTraffic} {
    upvar $raName resArray
    upvar $rvName retVal

    set retVal 0

    set resArray(groups) ""
    set resArray(clients) ""

    set mcIPFirstList [keylkeys groupMemStats group_addr]


    foreach mcIP $mcIPFirstList {

        lappend resArray(groups) $mcIP
        set hostStats [keylget groupMemStats group_addr.$mcIP.host_addr]

        set cliIPFirstList [keylkeys hostStats]


        foreach cliIP $cliIPFirstList {

            lappend resArray(clients) $cliIP
            set resArray($cliIP,groups) $mcIP
            keylget hostStats $cliIP.state resArray($cliIP,$mcIP,state)
            keylget hostStats $cliIP.join_latency resArray($cliIP,$mcIP,joinLat)
            keylget hostStats $cliIP.leave_latency resArray($cliIP,$mcIP,leaveLat)
            switch -- [string tolower $checkLatType] {
                "join" {
                    if {$resArray($cliIP,$mcIP,state) == "IDLE_MEMBER"} {
                        if {$isTraffic == "yes"} {
                            if {$resArray($cliIP,$mcIP,joinLat) == 0} {
                                set retVal 1
                            }
                        }
                    }
                }
                "leave" {
                    if {$resArray($cliIP,$mcIP,state) == "NON_MEMBER"} {
                        if {$isTraffic == "yes"} {
                            if {$resArray($cliIP,$mcIP,leaveLat) == 0} {
                                set retVal 1
                            }
                        }
                    }
                }
                default {
                    if {$isTraffic == "yes"} {
                        if {($resArray($cliIP,$mcIP, joinLat) == 0) || \
                                      ($resArray($cliIP,$mcIP,leaveLat) == 0)} {
                            set retVal 1
                        }
                    }
                }
            }

        }

    }

    return
}


# proc MLD_SessionsStats to get min,max,avg join/leave latency
proc MLD_SessionsStats {MLDSessionHandles} {

    set dataAppend 0

    # MLD info
    puts "\nChecking MLD info for Max, Min, Average latencies..."
    set ret [sth::emulation_mld_info -handle $MLDSessionHandles]
    set infoStatus [keylget ret status]
    if {! $infoStatus} {
        puts "Error getting MLD session status"
        puts "Error from command was $ret"
        set ::passFail FAIL
        exit

    } else {
        puts "The command for MLD to get status is $ret"
        set mldStatsInfo [keylget ret session]
        puts "MLD getting status for all sessions succeeded."
    }   ;# end if-else statement


    # Retrieve min, max, average join/leave latency
    foreach MLDSessionHandle $MLDSessionHandles {

        set minJoinLat [keylget mldStatsInfo $MLDSessionHandle.min_join_latency]
        set maxJoinLat [keylget mldStatsInfo $MLDSessionHandle.max_join_latency]
        set aveJoinLat [keylget mldStatsInfo $MLDSessionHandle.avg_join_latency]
        set minLeaveLat [keylget mldStatsInfo $MLDSessionHandle.min_leave_latency]
        set maxLeaveLat [keylget mldStatsInfo $MLDSessionHandle.max_leave_latency]
        set aveLeaveLat [keylget mldStatsInfo $MLDSessionHandle.avg_leave_latency]

        if { $dataAppend } {
            set fileid [open "Join_Leave_Latency.csv" a]
        } else {
            set fileid [open "Join_Leave_Latency.csv" w]
            puts $fileid "Session,MinJoin,MaxJoin,AveJoin,MinLeave,MaxLeave,AveLeave"
            set dataAppend 1
        }

        puts $fileid "$MLDSessionHandle,$minJoinLat,$maxJoinLat,$aveJoinLat,\
                      $minLeaveLat,$maxLeaveLat,$aveLeaveLat"

        close $fileid
    }

}


# proc MLD_DisplayLatencies to print out membership status and latencies
proc MLD_DisplayLatencies {siName} {
    upvar $siName statInfo
    set counter 1

    foreach mcIP $statInfo(groups) {
        set clientList {}

        foreach clientIP $statInfo(clients) {
            if {[lsearch -exact $clientList $clientIP] == -1} {
                puts "Counter: $counter"
                puts "$mcIP"
                puts "  HostAddr:       $clientIP"
                puts "  State:          $statInfo($clientIP,$mcIP,state)"
                puts "  Join Latency:   $statInfo($clientIP,$mcIP,joinLat)"
                puts "  Leave Latency:  $statInfo($clientIP,$mcIP,leaveLat)"

                incr counter
                set clientList [concat $clientList $clientIP]
            }
        }
    }

}


# proc MLD_CheckState to get the count of each membership status
proc MLD_CheckState {siName {secondsToWait 480}} {
    upvar $siName stateInfo

    puts "check_mld_state"

    # Assuming for now that everyone is joining everything (what is supported in STC)

    set undefined 0
    set non_member 0
    set delaying_member 0
    set idle_member 0
    set retrying_member 0
    set include 0
    set exclude 0

    set clientList {}

    foreach clientIP $stateInfo(clients) {

        if {[lsearch -exact $clientList $clientIP] == -1} {

            set clientList [concat $clientList $clientIP]

            foreach groupIP $stateInfo(groups) {

                switch -- [string tolower $stateInfo($clientIP,$groupIP,state)] {
                    undefined { incr undefined }
                    non_member { incr non_member }
                    include { incr include }
                    exclude { incr exclude }
                    retrying_member { incr retrying_member }
                    idle_member { incr idle_member }
                    delaying_member { incr delaying_member }
                }
            }
        }
    }
    after 1000
    puts "Undefined:       $undefined"
    puts "Non Member:      $non_member"
    puts "Delaying Member: $delaying_member"
    puts "Idle Member:     $idle_member"
    puts "Retrying Member: $retrying_member"
    puts "Include:         $include"
    puts "Exclude:         $exclude"
}


# proc incrementIpV6Address to increment a given IPv6 address by the increment value
proc incrementIpV6Address {ipToIncrement {ipIncrementValue 0:0:0:0:0:0:0:1} {expanded 0}} {
    #Make a fully qualified address to make things easy
    set ipToIncrementOctets {}
    set tmpOctets [split $ipToIncrement :]
    for {set i 0} {$i < [llength $tmpOctets]} {incr i} {
        set str [lindex $tmpOctets $i]
        if {[string length $str]} {
            lappend ipToIncrementOctets $str
        } else {
            #we hit a ::
            lappend ipToIncrementOctets 0
            #how many segments are missing
            set missingSegments [expr 8 - [llength $tmpOctets]]
            for {set seg 0} {$seg < $missingSegments} {incr seg} {
                lappend ipToIncrementOctets 0
            }  ;# end for loop
        }  ;# end if-else statement
    }  ;# end for loop
    set ipIncrementValueOctets {}
    set tmpOctets [split $ipIncrementValue :]
    for {set i 0} {$i < [llength $tmpOctets]} {incr i} {
        set str [lindex $tmpOctets $i]
        if {[string length $str]} {
            lappend ipIncrementValueOctets $str
        } else {
            #we hit a ::
            lappend ipIncrementValueOctets 0
            #how many segments are missing
            set missingSegments [expr 8 - [llength $tmpOctets]]
            for {set seg 0} {$seg < $missingSegments} {incr seg} {
                lappend ipIncrementValueOctets 0
            }  ;#  end for loop
        }  ;# end if-else statment
    }  ;# end for loop


    set ipList   $ipToIncrementOctets
    set incrVals $ipIncrementValueOctets
    set o8 [expr 0x[lindex $ipList 7] + 0x[lindex $incrVals 7]]
    set o7 [expr 0x[lindex $ipList 6] + 0x[lindex $incrVals 6]]
    set o6 [expr 0x[lindex $ipList 5] + 0x[lindex $incrVals 5]]
    set o5 [expr 0x[lindex $ipList 4] + 0x[lindex $incrVals 4]]
    set o4 [expr 0x[lindex $ipList 3] + 0x[lindex $incrVals 3]]
    set o3 [expr 0x[lindex $ipList 2] + 0x[lindex $incrVals 2]]
    set o2 [expr 0x[lindex $ipList 1] + 0x[lindex $incrVals 1]]
    set o1 [expr 0x[lindex $ipList 0] + 0x[lindex $incrVals 0]]

    if {$o8 > 0xffff} {incr o7; set o8 [expr $o8 - 0xffff]}
    if {$o7 > 0xffff} {incr o6; set o7 [expr $o7 - 0xffff]}
    if {$o6 > 0xffff} {incr o5; set o6 [expr $o6 - 0xffff]}
    if {$o5 > 0xffff} {incr o4; set o5 [expr $o5 - 0xffff]}
    if {$o4 > 0xffff} {incr o3; set o4 [expr $o4 - 0xffff]}
    if {$o3 > 0xffff} {incr o2; set o3 [expr $o3 - 0xffff]}
    if {$o2 > 0xffff} {incr o1; set o2 [expr $o2 - 0xffff]}
    if {$o1 > 0xfffe} {
        puts "ERROR: Cannot increment ip past fffe::0"
    }

    set ipv6Addr "[format %04X $o1]:[format %04X $o2]:[format %04X $o3]:[format %04X $o4]:[format %04X $o5]:[format %04X $o6]:[format %04X $o7]:[format %04X $o8]"

    if {$expanded} {
        return $ipv6Addr
    } else {

        set r ""
         foreach octet [split $ipv6Addr :] {
            append r [format %X: 0x$octet]
        }
        set r [string trimright $r :]
        regsub {(?:^|:)0(?::0)+(?::|$)} $r {::} r
        return $r
    }   ;# end if-else statement

}  ;# end procedure


# proc incrementMacAddress to increment a given MAC address by the increment value
proc incrMacAddress {address {incrValue 00.00.00.00.00.01}} {
    set ipList   [split $address    ".:"]
    set incrVals [split $incrValue ".:"]
    set o6 [expr 0x[lindex $ipList 5] + 0x[lindex $incrVals 5]]
    set o5 [expr 0x[lindex $ipList 4] + 0x[lindex $incrVals 4]]
    set o4 [expr 0x[lindex $ipList 3] + 0x[lindex $incrVals 3]]
    set o3 [expr 0x[lindex $ipList 2] + 0x[lindex $incrVals 2]]
    set o2 [expr 0x[lindex $ipList 1] + 0x[lindex $incrVals 1]]
    set o1 [expr 0x[lindex $ipList 0] + 0x[lindex $incrVals 0]]

    if {$o6 > 255} {incr o5; set o6 [expr $o6 - 256]}
    if {$o5 > 255} {incr o4; set o5 [expr $o5 - 256]}
    if {$o4 > 255} {incr o3; set o4 [expr $o4 - 256]}
    if {$o3 > 255} {incr o2; set o3 [expr $o3 - 256]}
    if {$o2 > 255} {incr o1; set o2 [expr $o2 - 256]}
    if {$o1 > 255} {
        puts "ERROR: Cannot increment mac past ff"
    }

    return "[format %02X $o1]:[format %02X $o2]:[format %02X $o3]:[format %02X $o4]:[format %02X $o5]:[format %02X $o6]"
}

#####################################################################################
# multicast group params
set num_multicast_groups        20000

# Source params
set source_ip                    "2000:11:1:0:0:0:0:2"
set source_gw_ip                 "2000:11:1:0:0:0:0:1"
set source_gw_mac                "33.33.00.00.00.01"

# MLD host params
set MLD_host_count              1
set MLD_host_ip_start           "2000:11:2:0:0:0:0:2"
set MLD_host_neighbor_ip_start  "2000:11:2:0:0:0:0:1"

set passFail PASS
set Result 0

set hPortlist ""
set media "copper"
set speed "ether1000"

set MAX_Streams 100

# Call off the internal apply
::sth::test_control -action enable

puts "\nConnecting and reserve the ports..."
set ret [sth::connect -device $device_list \
                      -port_list $portlist]

set returnedString [keylget ret status]
set hltHostPortList {}
if {$returnedString} {
    #Retrieve port handles for later use
    set hPort($device0,$sourcePort) [keylget ret port_handle.$device0.$sourcePort]
    set hPortlist [concat $hPortlist $hPort($device0,$sourcePort)]
    set hltSourcePort $hPort($device0,$sourcePort)
    puts "  Source Port Handle:  $hltSourcePort ($sourcePort)"
        
    set hPort($device1,$hostPort) [keylget ret port_handle.$device1.$hostPort]
    set hPortlist [concat $hPortlist $hPort($device1,$hostPort)]
    lappend hltHostPortList $hPort($device1,$hostPort)
} else {
    set passFail FAIL
    puts "Error retrieving the port handles, error message was $ret"
    exit
}  ;# end if-else

# Configuring ports
foreach portHnd $hPortlist {
    puts "\nConfiguring $portHnd with $media - $speed..."
    set ret [sth::interface_config   -port_handle $portHnd \
                                                -mode "config" \
                                                -speed $speed \
                                                -intf_mode ethernet \
                                                -phy_mode $media \
                                                -duplex full \
                                                -arp_send_req 1]
    set RStatus [keylget ret status]
    if {!$RStatus} {
        set passFail FAIL
        puts "Error configuring the port, error message was $ret"
        exit
    }
}

# MC groups
puts "\nCreating multicast group..."
set ret [sth::emulation_multicast_group_config -ip_addr_start "FF1E:0:0:0:0:1:0:1" \
                                                                 -mode "create" \
                                                                 -num_groups $num_multicast_groups]
 set returnedString [keylget ret status]
if {$returnedString} {
    set McGroupHandle [keylget ret handle]
    puts "  Multicast Group Handle:  $McGroupHandle"

} else {
    puts "Error creating MC groups, Error message was $ret"
    set passFail FAIL
    exit
}

# MLD host
puts "\nCreating MLD sessions..."
set temp_host_ip $MLD_host_ip_start
set temp_nei_ip  $MLD_host_neighbor_ip_start
foreach hltHostPort $hltHostPortList {
    puts "\nPort handle $hltHostPort"
    set ret [sth::emulation_mld_config \
                                -mode "create" \
                                -port_handle $hltHostPort \
                                -mld_version v2 \
                                -robustness 10 \
                                -count $MLD_host_count \
                                -intf_ip_addr $temp_host_ip \
                                -intf_ip_addr_step "0:0:0:0:0:0:0:1" \
                                -neighbor_intf_ip_addr $temp_nei_ip \
                                -neighbor_intf_ip_addr_step "0:0:0:0:0:0:0:0"]
     set returnedString [keylget ret status]
    if {$returnedString} {
        set MLDSessionHandle($hltHostPort) [keylget ret handle]
        puts "  MLD Session Handle:  $MLDSessionHandle($hltHostPort)"

    } else {
        puts "Fail to configure MLD hosts. Error message was $ret"
        set passFail FAIL
        exit
    }

    set temp_host_ip [incrementIpV6Address $temp_host_ip "0:0:1:0:0:0:0:0"]
    set temp_nei_ip [incrementIpV6Address $temp_nei_ip "0:0:1:0:0:0:0:0"]
}

# MLD group (set relationship)
puts "\nCreating MLD group membership..."
foreach hltHostPort $hltHostPortList {
    set ret [sth::emulation_mld_group_config \
                                -mode "create" \
                                -group_pool_handle $McGroupHandle \
                                -session_handle $MLDSessionHandle($hltHostPort)]
     set returnedString [keylget ret status]
    if {$returnedString} {
        set MLDGroupMemberHandle($hltHostPort) [keylget ret handle]
        puts "  MLDGroupMemberHandle Handle:  $MLDGroupMemberHandle($hltHostPort)"

    } else {
        puts "Fail to configure MLD group membership. Error message was $ret"
        set passFail FAIL
        exit
    }
}

# Multicast Traffic
puts "\nConfigure Multicast traffic"
set temp_mc_ip "FF1E:0:0:0:0:1:0:1"
set temp_mc_mac $source_gw_mac
set num_streams 0
for {set i 1} {$i <= $num_multicast_groups} {incr i} {

    if {$num_streams == $MAX_Streams} {
        break
    }

    set ret [sth::traffic_config \
                                        -mode "create" \
                                        -port_handle $hltSourcePort \
                                        -l2_encap "ethernet_ii" \
                                        -mac_src "00.12.00.17.00.01"  \
                                        -mac_dst $temp_mc_mac \
                                        -length_mode "fixed" \
                                        -l3_length 128 \
                                        -l3_protocol "ipv6" \
                                        -ipv6_src_addr $source_ip \
                                        -ipv6_dst_addr $temp_mc_ip \
                                        -rate_pps 50]
     set configStatus [keylget ret status]
    set temp_mc_ip [incrementIpV6Address $temp_mc_ip]
    set temp_mc_mac [incrMacAddress $temp_mc_mac "00.00.00.00.00.01"]

    incr num_streams
}

#config parts are finished

# Apply the configuration
::sth::test_control -action sync

puts "\nStarting traffic..."
set ret [sth::traffic_control \
                                -action "run" \
                                -port_handle $hltSourcePort]

set returnedString [keylget ret status]
# Sleep for 20s
puts "\nSleep for 20 seconds"
stc::sleep 20


# MLD join
foreach hltHostPort $hltHostPortList {

    puts "\nJoining MLD on session $MLDSessionHandle($hltHostPort)..."
    set ret [sth::emulation_mld_control \
                                    -mode "join" \
                                    -handle $MLDSessionHandle($hltHostPort) \
                                    -calculate_latency 0]
    set returnedString [keylget ret status]
}


puts "\nSleep for 10 seconds..."
stc::sleep 10


puts "\n#####Code to Check DUT#############"


# Check latency
if {[expr $num_multicast_groups*$MLD_host_count] <= 1000} {

    foreach hltHostPort $hltHostPortList {
        checkMLDSessionStats $MLDSessionHandle($hltHostPort) "join" "yes"
    }
}


# Sleep for 20s
puts "\nSleep for 20 seconds"
stc::sleep 20


# MLD leave
foreach hltHostPort $hltHostPortList {

    puts "\nLeaving MLD on session $MLDSessionHandle($hltHostPort)..."
    set ret [sth::emulation_mld_control \
                                            -mode "leave" \
                                            -handle $MLDSessionHandle($hltHostPort) \
                                            -calculate_latency 0]
    set returnedString [keylget ret status]
    if {$returnedString} {
        puts "MLD leave succesful "
    } else {
        puts "Fail to leave. Error message was $ret"
        set passFail FAIL
        exit
    }

}


# Check latency
if {[expr $num_multicast_groups*$MLD_host_count] <= 1000} {
    foreach hltHostPort $hltHostPortList {
        checkMLDSessionStats $MLDSessionHandle($hltHostPort) "leave" "yes"
    }
}



puts "\n#####Code to Check DUT#############"


puts "\nSleeping for 2 seconds..."
stc::sleep 2



puts "\nStopping traffic..."
set returnedString [sth::traffic_control -action "stop" \
                                         -port_handle $hltSourcePort]


set ret [::sth::cleanup_session -port_list $hPortlist]
set intStatus [keylget ret status]
if {! $intStatus} {
    set passFail FAIL
    puts "Error deleting port $port"
    exit
}   ;# end if statement



if {$passFail == "FAIL"} {
    puts "\nTest FAIL"
} else {
    puts "\nTest PASS"
}
puts "_SAMPLE_SCRIPT_SUCCESS"

