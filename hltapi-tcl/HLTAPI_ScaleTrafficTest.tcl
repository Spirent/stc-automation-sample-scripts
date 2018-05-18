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
# File Name:                 HLTAPI_ScaleTrafficTest.tcl
#
# Description:               This script demonstrates the use of Spirent HLTAPI to setup 1000 stream on each ports (2 ports) and start back 2 back traffic
#################################

# Run sample:
#            c:>tclsh HLTAPI_ScaleTrafficTest.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_ScaleTrafficTest-SSM.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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

#####################################
proc GetFrameMode {eth_type} {
	set frameModeList ""
	
	if {$eth_type == "eth10_100_1gig" || $eth_type == "eth_1gig" || $eth_type == "eth_10gig"} {
		set frameModeList {none}
    } elseif {$eth_type == "pos192"} {
		set frameModeList {SONET SDH}
	}
	
	return $frameModeList
}

proc CheckPosMixMatch {ifmode speed} {
    set posIfMode [string first "pos" $ifmode]
	if {($speed == "ether10000") && ($posIfMode != -1)} {
		###  If the port should be in ethernet mode, we don't want the pos if modes
		return 1
	}
	if {($speed == "oc192") && ($ifmode == "ethernet")} {
		###  If the port should be in pos mode, we don't want the ethernet if mode
		return 1
	}
}

proc ReadCardName {portHList} {
    upvar ret ret

    set cardID ""
    set portName ""

    foreach portHandle  $portHList {
    	set ret [sth::interface_stats -port_handle $portHandle]
        set cardID [keylget ret card_name]

        #port_name not supporte
        #set portName [keylget ret port_name]

        puts "\nTest run on port = $portHandle of card = $cardID"
    }

    return $cardID
}

proc GetCardSpeed {cardID} {
    puts "\nGet card speed list now"

    switch -- $cardID \
    XFP-1002A - \
    XFP-2002A - \
    XFP-1001A - \
    XFP-2001A { set speed_list [list ether10000] } \
    FBR-1001A - \
    FBR-2001A { set speed_list [list ether1000] } \
    CPR-1001A - \
    CPR-2001A - \
    EDM-1001A - \
    EDM-2001A - \
    EDM-1002A - \
    EDM-1003A - \
    EDM-2002A - \
    EDM-2003A { set speed_list [list ether10 ether100 ether1000] } \
    CPR-2002A { set speed_list [list ether10 ether100] } \
    MSA-2001A { set speed_list [list ether10000] } \
    UPY-2002A { set speed_list [list ether10000 oc192] } \
    default {
    set speed_list ""
    }

    return $speed_list
}


proc GetCardMedia {cardID} {
    puts "\nGet carde media now."

    switch -- $cardID \
    XFP-1002A - \
    XFP-2002A - \
    XFP-1001A - \
    XFP-2001A { set media_list [list fiber] } \
    FBR-1001A - \
    FBR-2001A { set media_list [list fiber] } \
    CPR-1001A - \
    CPR-2001A - \
    CPR-2002A { set media_list [list fiber] } \
    EDM-1001A - \
    EDM-2001A - \
    EDM-1002A - \
    EDM-1003A - \
    EDM-2002A - \
    EDM-2003A { set media_list [list fiber fiber] } \
    MSA-2001A { set media_list [list fiber]} \
    UPY-2002A { set media_list [list fiber]} \
    default {
    set media_list ""
    }

    return $media_list
}

proc GetCardEthType {cardID} {
    set ethType ""

    #Get speed list
    set speedL [GetCardSpeed $cardID]

    if {[lsearch $speedL "ether10"] != -1 && [lsearch $speedL "ether100"] != -1} {
        set ethType "eth10_100"

        if {[lsearch $speedL "ether1000"] != -1} {
            set ethType "eth10_100_1gig"
    }
    }

    if {[lsearch $speedL "ether1000"] != -1} {
        set ethType "eth_1gig"
    }

    if {[lsearch $speedL "ether10000"] != -1} {
        set ethType "eth_10gig"
    }

    if {[lsearch $speedL "oc192"] != -1} {
        set ethType "pos192"
    }

    return $ethType
}

#variable

set logValue 2
set HLTLogFile "HLT.log"
set media "copper"
set speed "ether1000"
set ifMode "ethernet"
set frameMode "none"
set mediaList $media
set speedList $speed
set FAIL 0
set PASS 1
set passFailArray($PASS) pass
set passFailArray($FAIL) fail
set passFail $PASS

set hPortlist ""
set mode "config"
set capture 1

# Test Configuration
set numberOfBurst 1
set numberOfPacket 1
set precedenceList {1}
set precedenceStepList {1}
set precedenceCountList {20}

# ipv4 stream
set ipv4StrLength 		128
set macSrcList 			"45.37.89.20.12.34"
set macDstList 			"98.52.57.12.34.67"
set macSrcMode 			fixed
set macDstMode 			fixed
set macSrcStep 			00.00.00.00.00.01
set macDstStep 			00.00.00.00.00.02
set macSrcCount			100
set macDstCount 		100
set ipv4StrSrcIPList	"2.2.2.2"
set ipv4StrDstIPList	"1.1.1.1"
set ipv4StrIPGatewayList	"1.1.1.1"
set ipv4StrSrcMode		fixed
set ipv4StrDstMode		fixed
set ipv4StrSrcCount		1
set ipv4StrDstCount 	1
set ipv4StrSrcStep		0.0.0.1
set ipv4StrDstStep  	0.0.0.2			  

set numberOfStreams 1000
set mediaList $media
set speedList $speed
set ifList $ifMode
set frameList $frameMode

set scriptLog [file rootname [info script]]

::sth::test_control -action enable

set mediaList $media
set speedList $speed

#Connect to chassis & reserve port
puts "Connecting to $device_list, $portlist"
set ret [sth::connect -device $device_list -port_list $portlist]

keylget ret port_handle.$device1.$port1 tgen1_port
set hPortlist "$tgen1_port"

#Read card name
set cardID [ReadCardName $hPortlist]

set eth_type [GetCardEthType $cardID]

if {[string tolower $media] == "all"} {
	#Get card speed list
	set mediaList [GetCardMedia $cardID]
}

if {[string tolower $speed] == "all"} {
	#Get card speed list
	set speedList [GetCardSpeed $cardID]
}

if {[string tolower $ifMode] == "all"} {
	#Get card speed list
	set ifList [GetIF $eth_type]
}

if {[string tolower $frameMode] == "all"} {
	#Get card speed list
	set frameList [GetFrameMode $eth_type]
}

foreach media $mediaList {
	foreach speed $speedList {
		foreach ifMode $ifList {
			foreach framingMode $frameList {
		
				if {[CheckPosMixMatch $ifMode $speed] == 1} {
					continue
				}
		
				foreach portHnd $hPortlist {
					set posIfMode [string first "pos" $ifMode]
					puts "Configuring $portHnd with Media: $media - Speed: $speed - Frame Mode: $framingMode - IF Mode: $ifMode..."
					if {$posIfMode != -1} {
						set RStatus [sth::interface_config -port_handle $portHnd \
	                         							-mode $mode \
	                         							-speed $speed \
                             							-intf_mode $ifMode \
				 			 							-phy_mode $media \
                                                        -framing $framingMode \
			         		 							-arp_send_req 0]	         		 					
					} else {
						set RStatus [sth::interface_config -port_handle $portHnd \
	                         							-mode $mode \
	                         							-speed $speed \
                             							-intf_mode $ifMode \
				 			 							-phy_mode $media \
			         		 							-duplex full \
			         		 							-arp_send_req 0]				
					}        		 					
				}	
		
				set srcIndex 0
				foreach portHnd $hPortlist {
					set dstIndex 0
					foreach dstPortHnd $hPortlist {
						if {$dstIndex!= $srcIndex} {
							for {set i 0} {$i < $numberOfStreams} {incr i} {
								puts "Creating streams -- $i"
 								set RStatus [sth::traffic_config -transmit_mode single_burst \
										-burst_loop_count $numberOfBurst \
										-pkts_per_burst $numberOfPacket \
										-mode create \
			   							-port_handle $portHnd \
			   							-rate_bps 500000]	   								
								# Apply at 700 streams
								if {[expr $i % 700] == 0} {
									puts "Do stc apply at $i"
									::sth::test_control -action sync
								}
							}
						}
						incr dstIndex
					}
					incr srcIndex
				} ; #end port config	       

				puts "Start Traffic"
				set RStatus [sth::traffic_control -action run -port_handle all]

				puts "Wait for 15 sec"
				after 15000
				set trafficStart [sth::traffic_control -port_handle "all" -action stop]
			}
		}

	}
}
sth::cleanup_session -port_handle $hPortlist


puts "_SAMPLE_SCRIPT_SUCCESS"
         							