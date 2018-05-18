
#################################
#
# File Name:         HLTAPI_Dot1x_basic.tcl
#
# Description:       This script demonstrates the use of Spirent HLTAPI to setup 802.1x devices.                  
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Interface config
#                    3. Download certificates file
#                    4. Config 802.1x supplicants
#                    5. Start 802.1x Authentication
#                    6. Check 802.1x Stats
#                    7. Stop 802.1x Authentication
#                    8. Release resources
#
# DUT configuration:
#           aaa new-model
#           aaa authentication dot1x default group radius
#           !
#          interface Vlan10
#           no shutdown
#           ip address 172.16.2.1 255.255.255.0
#         !
#         radius-server host 172.16.1.3 auth-port 1645 acct-port 1646 key radius1
#         dot1x system-auth-control
#         !
#         interface GigabitEthernet7/12
#           no shutdown
#           switchport
#           switchport access vlan 10
#           switchport mode access
#           authentication host-mode multi-auth
#           authentication port-control auto
#           dot1x pae authenticator
#           dot1x timeout quiet-period 1
#           dot1x max-req 10
#           dot1x max-reauth-req 10
#
# Topology
#                 STC Port1                                   switch                    
#            [802.1x supplicants]----------------[Authenticator + Authenticator Server]
#                     
###########################################################################################

# Run sample:
#            c:>tclsh HLTAPI_Dot1x_basic.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_Dot1x_basic.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

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
set enableHltLog 1

#######################################################
#Name: TurnOnCapture
#Author: Quinten Pierce
#Purpose: To turn on capture, either Hardware or Cut-Thru for a list of ports
#Input:  Port Handle list, capture type
#Output: fileNameList.  The list of filenames created is returned to the calling procedure/program
#                 Capture is turned on for the ports in the port handle list
#######################################################
proc TurnOnCapture {portHandleList {captureType  "HW"} {fileName "PortNum"}} {
    set captureHndList ""

    foreach portHnd $portHandleList {
        puts "Turn on capture on $portHnd"
        set capture [stc::get $portHnd -children-capture]
        stc::perform CaptureStart -CaptureProxyId $capture
        lappend captureHndList $capture
    }

    return $captureHndList
}   ;# end procedure

#######################################################
#Name: TurnOffCapture
#Author: Quinten Pierce
#Purpose: To turn off capture, and to retrieve the captured frames
#Input:  Port Handle list
#Output: None.  Capture is turned off, and the frames are retrieved
#######################################################
proc TurnOffCapture {portHandleList {fileName CaptureFilePort}} {
    set fileNameList {}
    set count 1;
    foreach portHnd $portHandleList {
        puts "Turn off capture on $portHnd"
        set captureHnd [stc::get $portHnd -children-capture]
        stc::perform CaptureStop -CaptureProxyId $captureHnd
        set name $fileName$count
        puts "Saving capture to $name"
        stc::perform SaveSelectedCaptureData -CaptureProxyId $captureHnd -filename "$name.pcap"
        lappend fileNameList "$name.pcap"
        incr count
    }
    puts "Save file Name list = $fileNameList"
    return $fileNameList
}

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

########################################
#Step1: Reserve and connect chassis ports
########################################

puts "Reserve and connect chassis ports"

set returnedString [sth::connect -device $device_list -port_list $port_list]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $status"
	return
}

keylget returnedString port_handle.$device2.$port2 hltHostPort
keylget returnedString port_handle.$device1.$port1 hltSourcePort


set portList "$hltHostPort $hltSourcePort"

########################################
# Step2: Interface config
########################################

puts "Interface config"

foreach port $portList {
    set returnedString [sth::interface_config	-mode config \
                            -port_handle        $port \
                            -intf_mode          "ethernet" \
                            -phy_mode           "fiber" \
                            -speed 	        "ether1000" \
                            -autonegotiation	1 \
                            -duplex		"full" \
                            -arp_send_req       1 ]
    
    keylget returnedString status status
    if {!$status} {
		puts $returnedString
        puts "  FAILED:  $returnedString"
		return
    }
}

########################################
# Step3: Download certificates file
########################################
#puts "Delete all certificates/PAC files"

#set returnedString [sth::emulation_dot1x_control  \
#                            -action               "delete_all" \
#                            -port_handle          $hltSourcePort ]
#
#puts "\n$returnedString"

puts "Download certificates/PAC files"

# Download certificates/PAC files for EAP FAST/TLS 
set returnedString [sth::emulation_dot1x_control  \
                            -action               "download" \
                            -certificate_dir      "./" \
                            -port_handle          $hltSourcePort ]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

########################################
# Step4: Config 802.1x supplicants
########################################

puts "Configuring 802.1x devices"

set returnedString [sth::emulation_dot1x_config   -mode     "create" \
                            -port_handle                    $hltSourcePort \
                            -name                           Dot1x_1 \
                            -num_sessions                   10 \
                            -encapsulation                  ethernet_ii_vlan \
                            -ip_version                     none \
                            -mac_addr                       00:66:00:00:00:01 \
                            -local_ip_addr                  20.0.0.22 \
                            -gateway_ip_addr                20.0.0.1  \
                            -vlan_id                        10 \
                            -supplicant_auth_rate           100 \
                            -supplicant_logoff_rate         300 \
                            -max_authentications            600 \
                            -retransmit_count               300 \
                            -eap_auth_method                tls \
                            -username                       Administrator \
                            -password                       acstest \
                            -certificate                    "test1.pem" \
                            ]
    
keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

#config parts are finished

keylget returnedString handle dot1xHandle

########################################
# Step5: Start Authentication
########################################

TurnOnCapture $hltSourcePort "port1"

stc::sleep 2
puts "Start Authentication"

set returnedString [sth::emulation_dot1x_control  \
                            -mode                start \
                            -port_handle         $hltSourcePort ]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

stc::sleep 20

TurnOffCapture $hltSourcePort "port1"

########################################
# Step6: Check 802.1x Stats
########################################

set returnedString [sth::emulation_dot1x_stats  \
                            -mode                aggregate \
                            -port_handle         $hltSourcePort ]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

set returnedString [sth::emulation_dot1x_stats  \
                            -mode                session \
                            -port_handle         $hltSourcePort ]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

########################################
# Step7: Stop Authentication
########################################

set returnedString [sth::emulation_dot1x_control  \
                            -mode                stop \
                            -port_handle         $hltSourcePort ]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

set returnedString [sth::emulation_dot1x_config   -mode     "delete" \
                            -handle               $dot1xHandle \
                   ]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}
########################################
#step8: Release resources
########################################
set returnedString [::sth::cleanup_session -port_list $portList]

keylget returnedString status status
if {!$status} {
	puts $returnedString
    puts "  FAILED:  $returnedString"
	return
}

puts "\n test over"
puts "_SAMPLE_SCRIPT_SUCCESS"