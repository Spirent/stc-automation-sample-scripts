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
# File Name:            HLTAPI_SIPv4_ProxyServer.tcl
#
# Description:          This script demonstrates the use of Spirent HLTAPI to setup through-going
#                       Proxy server SIPv4 test
#
# Test Step:            1. Reserve and connect chassis ports
#                       2. Configure SIP callees (UASs) on one port, and SIP callers (UACs) on the other port 
#                       3. Register caller and callee successfully
#                       4. Establish a call between callers and callees
#                       4. Retrieve SIP statistics
#                       5. Delete sip hosts and release port resources
#################################

# Run sample:
#            c:>tclsh HLTAPI_SIPv4_ProxyServer.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_SIPv4_ProxyServer.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

package require SpirentHltApi

set device_list      "10.61.39.164"
set port1        "8/3"
set port2        "8/4"
set i 1
foreach device $device_list {
    set device$i $device
    incr i
}
set device$i $device
set port_list "$port1 $port2"

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

::sth::test_config  -logfile sip_hltLogfile \
                    -log 1\
                    -vendorlogfile sip_stcExport\
                    -vendorlog 1\
                    -hltlog 1\
                    -hltlogfile sip_hltExport \
                    -hlt2stcmappingfile sip_hlt2StcMapping \
                    -hlt2stcmapping 1 \
                    -log_level 7

#step 1 : reserve and connect 
set returnedString [sth::connect -device $device_list -port_list $port_list]

puts $returnedString
keylget returnedString status status
if {!$status} {
puts $returnedString
    return "  FAILED:  $status"
}

keylget returnedString port_handle.$device2.$port2 hltHostPort

keylget returnedString port_handle.$device1.$port1 hltSourcePort

#step 2 : configure SIP callee
#
set returnedString [sth::emulation_sip_config -port_handle $hltSourcePort \
                                                -mode create \
                                                -count 10 \
                                                -name Caller1 \
                                                -mac_address_start 00:10:94:00:00:01 \
                                                -vlan_id1 500 \
                                                -vlan_ether_type1 0x8100 \
                                                -vlan_id_mode1 fixed \
                                                -vlan_id_step1 0 \
                                                -local_ip_addr 150.1.0.5 \
                                                -remote_ip_addr 150.1.0.1 \
                                                -gateway_enable 1 \
                                                -gateway_ipv4_address 150.1.0.3 \
                                                -local_username_prefix caller \
                                                -local_username_suffix 1000 \
                                                -local_username_suffix_step 3 \
                                                -registration_server_enable 1 \
                                                -registrar_address 150.1.0.5 \
                                                -desired_expiry_time 100000 \
                                                -call_accept_delay_enable 0 \
                                                -response_delay_interval 5 \
                                                -media_payload_type SIP_MEDIA_ITU_G711_64K_160BYTE \
                                                -media_port_number 50550 \
                                                -remote_username_prefix callee \
                                                -remote_username_suffix 300 \
                                                -remote_username_suffix_step 3]
puts "\n$returnedString"
                                                 #-remote_ip_addr_step 0 \
                                                 #-local_ip_addr_step 1 \
stc::perform saveasxml -filename sip1.xml

keylget returnedString status status
if {$status} {
    puts "\nConfiugring SIP callee is completed"
}

keylget returnedString handle sipCallee
#step 3: configure SIP caller
set returnedString [sth::emulation_sip_config -port_handle $hltHostPort \
                                                -mode create \
                                                -count 10 \
                                                -name Callee1 \
                                                -mac_address_start 00:10:94:00:10:03 \
                                                -vlan_id1 600 \
                                                -vlan_ether_type1 0x8100 \
                                                -vlan_id_mode1 fixed \
                                                -local_ip_addr 160.1.0.2 \
                                                -local_ip_addr_step 1 \
                                                -remote_ip_addr 160.1.0.1 \
                                                -remote_ip_addr_step 0 \
                                                -local_username_prefix callee \
                                                -local_username_suffix 300 \
                                                -local_username_suffix_step 3 \
                                                -registration_server_enable 1 \
                                                -registrar_address 150.1.0.5 \
                                                -desired_expiry_time 100000 \
                                                -media_payload_type SIP_MEDIA_ITU_G711_64K_160BYTE \
                                                -media_port_number 50550 \
                                                -remote_username_prefix caller \
                                                -remote_username_suffix 1000 \
                                                -remote_username_suffix_step 3 \
                                                -call_using_aor 1 \
                                                -remote_host 150.1.0.5 \
                                                -remote_host_step 1 \
                                                ]
puts "\n$returnedString"

keylget returnedString status status
if {$status} {
    puts "\nConfiugring SIP caller is completed"
}

keylget returnedString handle sipCaller
# save sip configuration to xml file
stc::perform saveasxml -filename sip2.xml
#config parts are finished

#turn on capture
TurnOnCapture $hltHostPort "CT"

set handleList "$sipCallee $sipCaller"
#step 4: register caller and callee
foreach sipHandle $handleList {
    set returnedString [sth::emulation_sip_control  -handle $sipHandle \
                                                    -action register]
    
    puts "\n$returnedString"
}
    
stc::sleep 10

#step 5: check the register state before establishing a sip call
set stateFlag 0
foreach sipHandle $handleList {
    set returnedString [sth::emulation_sip_stats    -action collect \
                                                    -mode device \
                                                    -handle $sipHandle]

    # Enum: NOT_REGISTERED|REGISTERING|REGISTRATION_SUCCEEDED|REGISTRATION_FAILED|REGISTRATION_CANCELED|UNREGISTERING
    keylget returnedString $sipHandle.registration_state regState
    if {!$stateFlag} {
        puts "\n Register state of $sipHandle : $regState"
        if {$regState != "REGISTRATION_SUCCEEDED"} {
            #turn off capture
            set stateFlag 1
            puts "\nFailed to register $sipHandle"
			return
        }
    } else {
        puts "\nFailed to register $sipHandle"
        TurnOffCapture $hltHostPort "SIP"
    }
}

#step 5: establish a call between caller and callee, initiated by sip caller
set returnedString [sth::emulation_sip_control  -action establish \
                                            -handle $sipCaller]

puts "\n$returnedString"

stc::sleep 2

#turn off capture
TurnOffCapture $hltHostPort "CT"

#step 6: retrieve statistics
set returnedString [sth::emulation_sip_stats    -handle $sipCaller \
                                                -action collect \
                                                -mode device ]

puts "\n$returnedString"

# step 7: delete sip host
set returnedString [sth::emulation_sip_config -handle $sipCaller \
                                                -mode delete \
                   ]
puts "\n$returnedString"

set returnedString [sth::emulation_sip_config -handle $sipCallee \
                                                -mode delete \
                   ]
puts "\n$returnedString"

# step 8: release resouces
set hPortlist "$hltSourcePort"
set returnedString [::sth::cleanup_session -port_list $hPortlist]

puts "_SAMPLE_SCRIPT_SUCCESS"