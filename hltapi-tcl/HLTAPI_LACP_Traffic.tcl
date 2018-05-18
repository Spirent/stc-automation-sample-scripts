################################################################################
#
# File Name:         HLTAPI_LACP_Traffic.tcl
#
# Description:       This script demonstrates how to create LACP header in streamblock. LACP header are available when you only specify Ethernet II for -l2_encap. 
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Create LACP header in raw streamblock
#                    3. Modify LACP header in raw streamblock
#                    4. Clean up session
#
################################################################################

# Run sample:
#c:\>tclsh HLTAPI_LACP_Traffic.tcl 10.61.47.129 1/1 1/2

package require SpirentHltApi

##############################################################
#config the parameters for the logging
##############################################################

set test_sta [sth::test_config\
        -log                                              1\
        -logfile                                          lacp_traffic_logfile\
        -vendorlogfile                                    lacp_traffic_stcExport\
        -vendorlog                                        1\
        -hltlog                                           1\
        -hltlogfile                                       lacp_traffic_hltExport\
        -hlt2stcmappingfile                               lacp_traffic_hlt2StcMapping\
        -hlt2stcmapping                                   1\
        -log_level                                        7]

set status [keylget test_sta status]
if {$status == 0} {
    puts "run sth::test_config failed"
    puts $test_sta
} else {
    puts "***** run sth::test_config successfully"
}

##############################################################
#config the parameters for optimization and parsing
##############################################################

set test_ctrl_sta [sth::test_control\
        -action                                           enable]

set status [keylget test_ctrl_sta status]
if {$status == 0} {
    puts "run sth::test_control failed"
    puts $test_ctrl_sta
} else {
    puts "***** run sth::test_control successfully"
}

########################################
# Step1: Reserve and connect chassis ports
########################################

set i 0
set device [lindex $argv 0]
set port_list {}
set port_list [lrange $argv 1 end]

set intStatus [sth::connect -device $device -port_list $port_list -break_locks 1 -offline 0]

set chassConnect [keylget intStatus status]
if {$chassConnect} {
    foreach port $port_list {
        incr i
        set port$i [keylget intStatus port_handle.$device.$port]
        puts "\n reserved ports : $intStatus"
    }
} else {
    set passFail FAIL
    puts "\nFailed to retrieve port handle! Error message: $intStatus"
}

########################################
# Step2: Create LACP header in raw streamblock
########################################
set streamblock_ret1 [sth::traffic_config    \
        -mode                                             create\
        -port_handle                                      $port1\
        -l2_encap                                         ethernet_ii\
        -lacp_subtype                                     08 \
        -lacp_version                                     08 \
        -lacp_actor_info                                  08 \
        -lacp_actor_info_len                              28 \
        -lacp_actor_sys_pri                               0008\
        -lacp_actor_sys_id                                00:00:00:00:00:08\
        -lacp_actor_key                                   0008\
        -lacp_actor_port_pri                              0008\
        -lacp_actor_port                                  0008\
        -lacp_actor_state                                 08\
        -lacp_actor_reserved                              000008\
        -lacp_partner_info                                08\
        -lacp_partner_info_len                            28\
        -lacp_partner_sys_pri                             0008\
        -lacp_partner_sys_id                              00:00:00:00:00:08\
        -lacp_partner_key                                 0008\
        -lacp_partner_port_pri                            0008\
        -lacp_partner_port                                0008\
        -lacp_partner_state                               08\
        -lacp_partner_reserved                            000008\
        -lacp_collector_info                              09\
        -lacp_collector_info_len                          24\
        -lacp_collector_max_delay                         32776\
        -lacp_collector_reserved                          7\
        -lacp_terminator_info                             7\
        -lacp_terminator_info_len                         7\
        -lacp_terminator_reserved                         7\
        -modifier_option                                  "{{lacp_subtype} {lacp_version} {lacp_actor_info} {lacp_actor_info_len}}"\
        -modifier_mode                                    "{{list} {increment} {decrement} {list}}"\
        -modifier_list_value                              "{{01 02 03} {99} {100} {3 4 5}}"\
        -modifier_count                                   "{{} {7} {8} {}}"\
        -modifier_step                                    "{{} {2} {3} {}}"\
        -modifier_repeat_count                            "{{} {0} {0} {}}"\
        -modifier_mask                                    "{{} {255} {255} {}}"\
]

set status [keylget streamblock_ret1 status]
if {$status == 0} {
    puts "run sth::traffic_config failed"
    puts $streamblock_ret1
} else {
    puts "***** run sth::traffic_config successfully"
    set sb1 [keylget streamblock_ret1 stream_id]
    puts "streamblock_ret1 is $streamblock_ret1"
}

stc::perform saveasxml -filename "lacp.xml"

########################################
# Step3: Modify LACP header in raw streamblock
########################################
set streamblock_ret2 [sth::traffic_config    \
        -mode                                             modify\
        -stream_id                                        $sb1\
        -lacp_subtype                                     09 \
        -lacp_version                                     09 \
        -lacp_actor_info                                  09 \
        -lacp_actor_info_len                              29 \
        -lacp_actor_sys_pri                               0009\
        -lacp_actor_sys_id                                00:00:00:00:00:09\
        -lacp_actor_key                                   0009\
        -lacp_actor_port_pri                              0009\
        -lacp_actor_port                                  0009\
        -lacp_actor_state                                 09\
        -lacp_actor_reserved                              000009\
        -lacp_partner_info                                09\
        -lacp_partner_info_len                            29\
        -lacp_partner_sys_pri                             0009\
        -lacp_partner_sys_id                              00:00:00:00:00:09\
        -lacp_partner_key                                 0009\
        -lacp_partner_port_pri                            0009\
        -lacp_partner_port                                0009\
        -lacp_partner_state                               09\
        -lacp_partner_reserved                            000009\
        -lacp_collector_info                              10\
        -lacp_collector_info_len                          25\
        -lacp_collector_max_delay                         32777\
        -lacp_collector_reserved                          77\
        -lacp_terminator_info                             77\
        -lacp_terminator_info_len                         77\
        -lacp_terminator_reserved                         77\
        -modifier_option                                  "{{lacp_subtype} {lacp_version} {lacp_actor_info} {lacp_actor_info_len}}"\
        -modifier_mode                                    "{{list} {increment} {decrement} {list}}"\
        -modifier_list_value                              "{{04 05 06} {999} {888} {7 8 9}}"\
        -modifier_count                                   "{{} {8} {18} {}}"\
        -modifier_step                                    "{{} {12} {13} {}}"\
        -modifier_repeat_count                            "{{} {0} {0} {}}"\
        -modifier_mask                                    "{{} {255} {255} {}}"\
]

set status [keylget streamblock_ret1 status]
if {$status == 0} {
    puts "run sth::traffic_config failed"
    puts $streamblock_ret2
} else {
    puts "***** run sth::traffic_config successfully"
    puts "streamblock_ret2 is $streamblock_ret2"
}

stc::perform saveasxml -filename "lacp_after_modify.xml"

#########################
# Step4: Clean up session
#########################

set cleanup_sta [sth::cleanup_session\
        -port_handle                                      $port1 $port2\
        -clean_dbfile                                     1]

set status [keylget cleanup_sta status]
if {$status == 0} {
    puts "run sth::cleanup_session failed"
    puts $cleanup_sta
} else {
    puts "***** run sth::cleanup_session successfully"
}

puts "**************Finish***************"