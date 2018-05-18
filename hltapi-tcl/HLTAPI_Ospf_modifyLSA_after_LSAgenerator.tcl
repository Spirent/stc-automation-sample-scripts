################################################################################
#
# File Name:         HLTAPI_Ospf_modifyLSA_after_LSAgenerator.tcl
#
# Description:       This script demonstrates how to create LSAs by LSA generator,and then modify attributes of LSAs.
#
# Test Step:         1. Reserve and connect chassis ports
#                    2. Create 1 ospfv2 router using emulation_ospf_config
#                    3. Create ospfv2 lsas using emulation_ospf_lsa_generator when session_type is ospfv2
#                    4. Modify ospfv2 lsas by emulation_ospf_lsa_config
#                    5. Delete ospfv2 lsas using emulation_ospf_lsa_generator when mode is delete  
#                    6. Release Resources
#
#Topology
#                              STC Port1  
#                          [1 OSPFv2 router]                                          
#
################################################################################

# Run sample:
#            c:\>tclsh HLTAPI_Ospf_modifyLSA_after_LSAgenerator.tcl 10.61.44.2 1/1

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

##############################################################
#config the parameters for the logging
##############################################################

set test_sta [sth::test_config\
        -log                                              1\
        -logfile                                          ospf_modifyLSA_after_LSAgenerator_logfile\
        -vendorlogfile                                    ospf_modifyLSA_after_LSAgenerator_stcExport\
        -vendorlog                                        1\
        -hltlog                                           1\
        -hltlogfile                                       ospf_modifyLSA_after_LSAgenerator_hltExport\
        -hlt2stcmappingfile                               ospf_modifyLSA_after_LSAgenerator_hlt2StcMapping\
        -hlt2stcmapping                                   1\
        -log_level                                        7]

set status [keylget test_sta status]
if {$status == 0} {
    puts "<error>run sth::test_config failed"
    puts $test_sta
} else {
    puts "***** run sth::test_config successfully\n"
}


########################################
# Step1: Reserve and connect chassis ports
########################################

set i 0
set intStatus [sth::connect -device $device_list -port_list $port_list -offline 1];

set chassConnect [keylget intStatus status]
if {$chassConnect} {
    foreach port $port_list {
        incr i
        set port$i [keylget intStatus port_handle.$device.$port]
        puts "\n reserved ports : $intStatus"
    }
} else {
    set passFail FAIL
    puts "\n<error>Failed to retrieve port handle! Error message: $intStatus"
}

###################################################################
# Step2: Create 1 ospfv2 router using emulation_ospf_config
###################################################################

set ospf_v2 [sth::emulation_ospf_config\
        -mode                                             create\
        -port_handle                                      $port1 \
        -session_type                                     ospfv2\
        -intf_ip_addr                                     192.85.1.3 \
        -hello_interval                                   1 \
        -router_priority                                  10 \
        -gateway_ip_addr                                  192.85.1.1 \
        -area_id                                          1.1.1.1 \
    ]

set status [keylget ospf_v2 status]
if {$status == 0} {
    puts "<error>run sth::emulation_ospf_config failed\n"
    puts $ospf_v2
} else {
    puts "***** run sth::emulation_ospf_config successfully\n"
    puts "return of ospfv2_config:$ospf_v2"
}

#get handles of above OSPF routers
set ospf_v2_handle [keylget ospf_v2 handle]
puts "ospf_v2_handle : $ospf_v2_handle"


############################################################################################
# Step3: Create ospfv2 lsas using emulation_ospf_lsa_generator when session_type is ospfv2
############################################################################################
set ospfLsaGenv4 [sth::emulation_ospf_lsa_generator\
        -handle $ospf_v2_handle\
        -mode create\
        -topo_type full_mesh\
        -session_type ospfv2\
        -full_mesh_num_of_routers 2\
        -full_mesh_emulated_router_pos member_of_mesh\
        -ospfv2_ip_addr_start 1.1.1.1\
        -ospfv2_ip_addr_end   224.255.255.255\
        -ospfv2_create_num_point_to_point  true\
        -ospfv2_area_type nssa\
        -ospfv2_intf_addr_start 1.1.1.2\
        -ospfv2_intf_prefix_length 28\
        -ospfv2_enable_loopback_advertise true\
        -ospfv2_router_id_start 1.1.1.1\
        -ospfv2_router_id_step  0.0.0.2\
        -ospfv2_stub_emulated_routers all\
        -ospfv2_stub_simulated_routers edge\
        -ospfv2_stub_num_of_routes 2\
        -ospfv2_stub_weight_route_assign byspeed\
        -ospfv2_stub_ip_addr_start 2.2.2.2\
        -ospfv2_stub_ip_addr_end  224.255.255.255\
        -ospfv2_stub_enable_ip_addr_override false\
        -ospfv2_stub_disable_route_aggr      true\
        -ospfv2_stub_prefix_len_dist_type   linear\
        -ospfv2_stub_prefix_len_start       30\
        -ospfv2_stub_prefix_len_end         30\
        -ospfv2_stub_prefix_len_dist        50\
        -ospfv2_stub_primary_metric         50000\
        -ospfv2_stub_secondary_metric       60000\
        -ospfv2_sum_emulated_routers all\
        -ospfv2_sum_simulated_routers edge\
        -ospfv2_sum_num_of_routes 2\
        -ospfv2_sum_weight_route_assign byspeed\
        -ospfv2_sum_ip_addr_start 2.2.2.2\
        -ospfv2_sum_ip_addr_end  224.255.255.255\
        -ospfv2_sum_enable_ip_addr_override false\
        -ospfv2_sum_disable_route_aggr      true\
        -ospfv2_sum_prefix_len_dist_type   linear\
        -ospfv2_sum_prefix_len_start       30\
        -ospfv2_sum_prefix_len_end         30\
        -ospfv2_sum_prefix_len_dist        50\
        -ospfv2_sum_primary_metric         50000\
        -ospfv2_sum_secondary_metric       60000\
        -ospfv2_ext_emulated_routers all\
        -ospfv2_ext_simulated_routers edge\
        -ospfv2_ext_num_of_routes 2\
        -ospfv2_ext_weight_route_assign byspeed\
        -ospfv2_ext_ip_addr_start 2.2.2.2\
        -ospfv2_ext_ip_addr_end  224.255.255.255\
        -ospfv2_ext_enable_ip_addr_override false\
        -ospfv2_ext_disable_route_aggr      true\
        -ospfv2_ext_prefix_len_dist_type   linear\
        -ospfv2_ext_prefix_len_start       30\
        -ospfv2_ext_prefix_len_end         30\
        -ospfv2_ext_prefix_len_dist        50\
        -ospfv2_ext_primary_metric         50000\
        -ospfv2_ext_secondary_metric       60000\
        -ospfv2_sub_tlv                    max_bw|max_rsv_bw\
    ]

set status [keylget ospfLsaGenv4 status]
if {$status == 0} {
    puts "<error>run sth::emulation_ospf_lsa_generator ospfv2 failed"
    puts $ospfLsaGenv4
} else {
    puts "emulation_ospf_lsa_generator Ospfv2 returned : $ospfLsaGenv4\n"
    puts "***** run sth::emulation_ospf_lsa_generator ospfv2 successfully"
}
#Handle used for delete mode
set Ospfv2Genhandle [keylget ospfLsaGenv4 handle]

########################################################################################
# Step4: Modify ospfv2 lsas by emulation_ospf_lsa_config
########################################################################################

#Handle used for modifying summary_lsa
set summary_lsa_block_handle [keylget ospfLsaGenv4 summary_lsa_block_handle]

foreach summary_lsa_block_handle $summary_lsa_block_handle {
    set device_ret0_router2 [sth::emulation_ospf_lsa_config\
        -ls_age                                           77\
        -ls_seq                                           177\
        -lsa_handle                                       $summary_lsa_block_handle\
        -ls_checksum                                      good\
        -mode                                             modify\
        -type                                             summary_pool\
        -summary_route_category                           primary\
    ]

    set status [keylget device_ret0_router2 status]
    if {$status == 0} {
        puts "run sth::emulation_ospf_lsa_config failed"
        puts $device_ret0_router2
    } else {
        puts "***** run sth::emulation_ospf_lsa_config successfully"
        puts $device_ret0_router2
    }
}

#Handle used for modifying stub_lsa (router_lsa)
set stub_lsa_block_handle [keylget ospfLsaGenv4 stub_lsa_block_handle]

foreach stub_lsa_block_handle $stub_lsa_block_handle {
    set device_ret0_router1 [sth::emulation_ospf_lsa_config\
        -ls_age                                           88\
        -ls_seq                                           188\
        -lsa_handle                                       $stub_lsa_block_handle\
        -ls_checksum                                      good\
        -mode                                             modify\
        -type                                             router\
        -router_route_category                            any\
    ]

    set status [keylget device_ret0_router1 status]
    if {$status == 0} {
        puts "run sth::emulation_ospf_lsa_config failed"
        puts $device_ret0_router1
    } else {
        puts "***** run sth::emulation_ospf_lsa_config successfully"
        puts $device_ret0_router1
    }
}

#Handle used for modifying as_external_lsa 
set external_lsa_block_handle [keylget ospfLsaGenv4 external_lsa_block_handle]

foreach external_lsa_block_handle $external_lsa_block_handle {
    set device_ret0_router0 [sth::emulation_ospf_lsa_config\
        -ls_age                                           99\
        -ls_seq                                           199\
        -lsa_handle                                       $external_lsa_block_handle\
        -ls_checksum                                      bad\
        -mode                                             modify\
        -type                                             ext_pool\
        -external_prefix_route_category                   unique\
    ]

    set status [keylget device_ret0_router0 status]
    if {$status == 0} {
        puts "run sth::emulation_ospf_lsa_config failed"
        puts $device_ret0_router0
    } else {
        puts "***** run sth::emulation_ospf_lsa_config successfully"
    }
}

#config part is finished
stc::perform SaveAsXml -filename OSPF_modifyLSA_after_LSAgenerator.xml

##################################################################################
# Step5: Delete ospfv2 lsas using emulation_ospf_lsa_generator when mode is delete  
##################################################################################
set delete_status [sth::emulation_ospf_lsa_generator -mode delete -handle $Ospfv2Genhandle]
set status [keylget delete_status status]
if {$status == 0} {
    puts "<error>run sth::emulation_ospf_lsa_generator ospfv2 delete failed"
    puts $delete_status
} else {
    puts "***** run sth::emulation_ospf_lsa_generator ospfv2 delete successfully"
}

#save as xml
stc::perform SaveAsXml -filename OSPF_modifyLSA_after_LSAgenerator_afterdelete.xml

##############################################################
# Step6: Release Resources
##############################################################

set cleanup_sta [sth::cleanup_session\
        -port_handle                                      $port1 \
        -clean_dbfile                                     1]

set status [keylget cleanup_sta status]
if {$status == 0} {
    puts "run sth::cleanup_session failed"
    puts $cleanup_sta
} else {
    puts "***** run sth::cleanup_session successfully"
}

puts "**************Finish***************"
