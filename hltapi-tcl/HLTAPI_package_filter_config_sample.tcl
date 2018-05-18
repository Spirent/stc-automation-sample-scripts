##
# Sample file showing the use of HLTAPI commands for configuring package filter
###################################

# Run sample:
#            c:>tclsh HLTAPI_package_filter_config_sample.tcl 10.61.44.2 3/1 3/3
#            c:>tclsh HLTAPI_package_filter_config_sample.tcl "10.61.44.2 10.61.44.7" 3/1 3/3

package require SpirentHltApi

set chassis_list      [lindex $argv 0]
set clientPort        [lindex $argv 1]
set serverPort        [lindex $argv 2]
set i 1
foreach chassis $chassis_list {
    set chassis$i $chassis
    incr i
}
set chassis$i $chassis
set portList [list $clientPort $serverPort]

set num_sessions 32768
#gpib cmdlogon
#gpib cmddispon

# Connecting to the chassis and locking the ports
set connectRetList [sth::connect -device $chassis_list -port_list $portList ]

puts $connectRetList

# Extracting the port handles from the return list
set port_handle_client [keylget connectRetList port_handle.$chassis1.$clientPort]
set port_handle_server [keylget connectRetList port_handle.$chassis2.$serverPort]  

puts "port_handle_client $port_handle_client port_handle_server $port_handle_server"

#set hPort(1) [keylget cmdReturn port_handle.$device.$port1]
#set hPort(2) [keylget cmdReturn port_handle.$device.$port2]

# Setting up the devices
sth::interface_config -port_handle $port_handle_client -mode config -intf_mode ethernet -vlan 1 
sth::interface_config -port_handle $port_handle_server -mode config -intf_mode ethernet -vlan 1 ;

puts [sth::packet_config_filter -port_handle $port_handle_client \
                   -mode add\
                   -filter {pattern {\
         {-pdu ethernetii -field srcmac -value 08:00:00:01:01:02  -field ethertype -value 86dd   \
          -frameconfig ethernetii:vlan:vlan:ipv6:udp} AND \
          {-pdu ipv6 -field sourceaddr -value 2001::01 -frameconfig ethernetii:vlan:vlan:ipv6:udp} AND \
          {-pdu udp -field sourceport -value 35 \
          -frameconfig ethernetii:vlan:vlan:ipv6:udp \
           } AND \
           {-pdu udp -field destport -value 33 \
          -frameconfig ethernetii:vlan:vlan:ipv6:udp }}} ]

#config parts are finished

puts "_SAMPLE_SCRIPT_SUCCESS" 
exit

 