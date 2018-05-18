#####################################################################
#Decription:
#    configure interface port_percent when select port_based  on stc ports in back-to-back mode
#Autor: Juan,Lu
######################################################################
package require SpirentHltApi

set enableLog 1
if {$enableLog} {
    ::sth::test_config  -logfile hltLogfile \
                        -log 1\
                        -vendorlogfile stcExport\
                        -vendorlog 1\
                        -hltlog 1\
                        -hltlogfile hltExport\
                        -hlt2stcmappingfile hlt2StcMapping1 \
                        -hlt2stcmapping 1\
                        -log_level 7
}
########################################
#Step1: Reserve and connect chassis ports
########################################
puts "\nStep1: Reserve and connect chassis ports"
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
set returnedString [sth::connect -device $device_list -port_list $port_list]

keylget returnedString status status
if {$status} {
    puts "\n reserved ports : Pass"
} else {

    puts "\n<error>Failed to retrieve port handle! Error message:\n$returnedString\n"
} 

keylget returnedString port_handle.$device1.$port1 hltSrcPort
keylget returnedString port_handle.$device2.$port2 hltDstPort

set portList "$hltSrcPort $hltDstPort"

##############################################################
#Step2: interface config
##############################################################
puts "\nStep2: interface config"
set int_ret0 [sth::interface_config \
        -mode                                             config \
        -port_handle                                      $hltSrcPort \
        -create_host                                      false \
        -intf_mode                                        ethernet\
        -scheduling_mode                                  PORT_BASED\
        -port_load                                        100\
        -port_loadunit                                    PERCENT_LINE_RATE\
        -src_mac_addr_step                                00:00:00:00:00:01 \
        -src_mac_addr                                     00:11:94:bc:00:02 \
        -speed                                            ether10000\
]

set status [keylget int_ret0 status]
if {$status == 0} {
    puts "\n<error>run sth::interface_config failed"
    puts $int_ret0
} else {
    puts "***** run sth::interface_config successfully"
}
##############################################################
#Step3: Check interface stats
##############################################################
puts "\nStep3: Check interface stats"
set rtn [sth::interface_stats \
    -port_handle $hltSrcPort\
]
set status [keylget rtn status]
if {$status == 0} {
    puts "\n<error>run sth::interface_stats failed"
    puts $rtn
} else {
    puts "***** run sth::interface_stats successfully"
    keylget rtn intf_speed validspeed
   }


if {$validspeed == 10000} {
    puts "\nconfig port speed successfully"
} else {
    puts "\nport_percent is not 10000"
    puts "\nintf_speed:$validspeed"
}
##############################################################
#Step4:clean up the session, release the ports reserved
##############################################################
puts "\nStep4:clean up the session, release the ports reserved"
set cleanup_sta [sth::cleanup_session\
        -port_handle                                      $portList\
        -clean_dbfile                                     1]

set status [keylget cleanup_sta status]
if {$status == 0} {
    puts "\n<error>run sth::cleanup_session failed"
    puts $cleanup_sta
} else {
    puts "***** run sth::cleanup_session successfully"
}

puts "\n**************Script Finish***************"
puts "\n**************_SAMPLE_SCRIPT_SUCCESS***************"