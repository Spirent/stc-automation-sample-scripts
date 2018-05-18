###################
#  enhances for emulation_ospf_topology_route_config
#
#1)	For these LAS (type ext_routes, nssa_routes, summary_routes, router), a default router LSA for the emulated router1 (created by emulation_ospf_config)will be created automatically.
#2)	If a gird of simulated routers are created firstly on router2, and AS-external/NSSA/summary LSA will be created on the same router2, then you can "connect" the latter LSA with one of the simulated router, by using ?external_connect? to select the advertising router.  
#3)	Enhance both for OSPFv2 and OSPFv3
#
# author: xiaozhi, liu  2011-09-01
####################

# Run sample:
#            c:>tclsh HLTAPI_Ospfv2_topology_enhance.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_Ospfv2_topology_enhance.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

package require SpirentHltApi

set device_list      [lindex $argv 0]
set hPort1        [lindex $argv 1]
set hPort2        [lindex $argv 2]
set i 0
foreach device $device_list {
    set device$i $device
    incr i
}
set device$i $device
set port_list "$hPort1 $hPort2";

::sth::test_config  -logfile hltLogfile \
                    -log 1\
                    -vendorlogfile stcExport\
                    -vendorlog 1\
                    -hltlog 1\
                    -hltlogfile hltExport\
                    -hlt2stcmappingfile hlt2StcMapping \
                    -hlt2stcmapping 1\
                    -log_level 7

set rst [sth::connect -device $device_list -port_list $port_list -offline 1]

keylget rst status iStatus

if {$iStatus} {
    keylget rst port_handle.$device0.$hPort1 hPort1
	keylget rst port_handle.$device1.$hPort2 hPort2
} else {
	puts "\nthere was an error";
	return
}

set ret [::sth::emulation_ospf_config \
                               -mode create \
                               -port_handle $hPort1 \
                               -area_id 0.0.0.4 \
                               -count 4 \
                               -dead_interval 200  \
                               -demand_circuit 1  \
                               -intf_ip_addr 1.100.0.1  \
                               -gateway_ip_addr 1.100.0.101  \
                               -intf_ip_addr_step 0.0.0.1  \
                               -gateway_ip_addr_step 0.0.0.1  \
                               -graceful_restart_enable 1 \
                               -router_id 2.2.2.2 \
                               -router_id_step 0.0.0.10 \
                               -session_type ospfv2 \
							   -mac_address_start 00:10:94:00:00:31 ]

puts $ret
keylget ret handle handle_list1

set router1 [lindex $handle_list1 0]
set router2 [lindex $handle_list1 1]
set router5 [lindex $handle_list1 2]

set ret [::sth::emulation_ospf_config \
                               -mode create \
                               -port_handle $hPort2 \
                               -area_id 0.0.0.4 \
                               -area_type stub \
                               -count 4 \
                               -dead_interval 200  \
                               -demand_circuit 1  \
                               -intf_ip_addr 1.100.0.101  \
                               -gateway_ip_addr 1.100.0.1  \
							   -graceful_restart_enable 1 \
                               -router_id 1.1.1.1 \
                               -router_id_step 0.0.0.1 \
                               -session_type ospfv2 \
							   -mac_address_start 00:10:94:00:00:32 ]
puts $ret

keylget ret handle handle_list2

set router3 [lindex $handle_list2 0]
set router4 [lindex $handle_list2 1]
set router6 [lindex $handle_list2 2]

puts "\n$router1, type ext_routes" 

set ret [::sth::emulation_ospf_topology_route_config  -mode create\
                                      -type ext_routes \
				      -handle $router1 \
				      -external_number_of_prefix 30 \
				      -external_prefix_start 91.0.0.1 \
				      -external_prefix_step 2  \
				      -external_prefix_length 32 \
				      -external_prefix_type 2]

puts $ret
#{external {{external_lsas externallsablock1} {version ospfv2} {connected_routers routerlsa1}}} {status 1} {elem_handle externallsablock1}

puts "\n$router1, type ext_routes" 
set ret [::sth::emulation_ospf_topology_route_config  -mode create\
                                      -type ext_routes \
				      -handle $router1 \
				      -external_number_of_prefix 20 \
				      -external_prefix_start 191.0.0.1 \
				      -external_prefix_step 2  \
				      -external_prefix_length 32 \
				      -external_prefix_type 2]

puts $ret
#{external {{external_lsas externallsablock2} {version ospfv2} {connected_routers routerlsa1}}} {status 1} {elem_handle externallsablock2}

puts "\n$router2, type grid+ext_routes"

set ret [sth::emulation_ospf_topology_route_config -mode create \
                                        -handle $router2 \
                                        -type grid \
                                        -grid_connect  "1 1" \
                                        -grid_col 2 \
                                        -grid_row  2 \
                                        -grid_link_type ptop_unnumbered \
                                        -grid_router_id 2.2.2.2 \
                                        -grid_router_id_step  0.0.0.1 ]
puts $ret
keylget ret grid.connected_session gridSession
keylget ret elem_handle ospfGrid
#{status 1} {elem_handle ospfGrid1} {grid {{connected_session {{routerlsa6 {{row 1} {col 1}}}}} {router {{1 {{1 routerlsa2} {2 routerlsa3}}} {2 {{1 routerlsa4} {2 routerlsa5}}}}}}}


set ret [::sth::emulation_ospf_topology_route_config  -mode create\
                                      -type ext_routes \
				      -handle $router2 \
                                      -external_connect "2 2" \
				      -external_number_of_prefix 30 \
				      -external_prefix_start 91.0.0.1 \
				      -external_prefix_step 2  \
				      -external_prefix_length 32 \
				      -external_prefix_type 2]

puts $ret

#{external {{external_lsas externallsablock2} {version ospfv2} {connected_routers routerlsa2}}} {status 1} {elem_handle externallsablock2}

puts "\n type nssa_routes"

set ret [::sth::emulation_ospf_topology_route_config  -mode create\
                                      -type nssa_routes \
				      -handle $router1 \
				      -nssa_number_of_prefix 30 \
				      -nssa_prefix_forward_addr 10.0.0.1 \
                                      -nssa_prefix_start 90.0.0.1 \
				      -nssa_prefix_step 2  \
				      -nssa_prefix_length 32 \
                                      -nssa_prefix_metric 5 \
				      -nssa_prefix_type 2]

puts $ret

set ret [::sth::emulation_ospf_topology_route_config  -mode create\
                                      -type nssa_routes \
                                      -nssa_connect "1 1" \
				      -handle $router2 \
				      -nssa_number_of_prefix 30 \
				      -nssa_prefix_forward_addr 10.0.0.1 \
                                      -nssa_prefix_start 90.0.0.1 \
				      -nssa_prefix_step 2  \
				      -nssa_prefix_length 32 \
                                      -nssa_prefix_metric 5 \
				      -nssa_prefix_type 2]

puts $ret

#{nssa {{nssa_lsas externallsablock4} {version ospfv2} {connected_routers routerlsa1}}} {status 1} {elem_handle externallsablock4}

puts "\n$router3, type summary_routes" 
set ret [sth::emulation_ospf_topology_route_config -mode create \
					-handle $router3 \
					-type summary_routes \
                                        -summary_number_of_prefix 20 \
					-summary_prefix_start 91.0.1.0 \
					-summary_prefix_step 2 \
					-summary_prefix_length 27 \
					-summary_prefix_metric 10]
puts $ret 

puts "\n$router4, type router" 
set ret [sth::emulation_ospf_topology_route_config -mode create \
                                        -handle $router4 \
                                        -link_enable 0 \
                                        -type router \
                                        -router_id 10.0.0.1]
puts $ret

puts "\n$router4, type router" 
set ret [sth::emulation_ospf_topology_route_config -mode create \
                                        -handle $router4 \
                                        -link_enable 1 \
                                        -type router \
                                        -router_id 20.0.0.1]
puts $ret

stc::perform saveasxml -filename OSPF_route_config.xml
#config parts are finished

puts "_SAMPLE_SCRIPT_SUCCESS"
