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

# File Name:                 Anatomy.tcl
# Description:               This script demonstrates basic features 
#                            such as creating streams, generating traffic,
#                            enabling capture, saving realtime results
#                            to files, and retrieving results.

set ENABLE_CAPTURE 1

package require SpirentTestCenter

# Retrieve and display the current API version.
  puts "SpirentTestCenter system version:\t[stc::get system1 -Version]"

# Physical topology
  set szChassisIp1 10.29.0.49
  set szChassisIp2 10.29.0.45
  set txPortLoc //$szChassisIp1/1/1
  set rxPortLoc //$szChassisIp2/1/1

if {[catch {

# Create the root project object
  puts "Creating project ..."
  set hProject [stc::create project]

# Create ports
  puts "Creating ports ..."
  set hPortTx [stc::create port -under $hProject -location $txPortLoc -useDefaultHost False ]
  set hPortRx [stc::create port -under $hProject -location $rxPortLoc -useDefaultHost False ]

# Configure physical interface.
  set hPortTxCopperInterface [stc::create EthernetCopper -under $hPortTx]

# Attach ports. 
# Connects to chassis, reserves ports and sets up port mappings all in one step.
# By default, connects to all previously created ports.
  puts "Attaching ports $txPortLoc $rxPortLoc"
  stc::perform AttachPorts

# Apply the configuration.
  puts "Apply configuration"
  stc::apply

# Retrieve the generator and analyzer objects.
  set hGenerator [stc::get $hPortTx -children-Generator]  
  set hAnalyzer [stc::get $hPortRx -children-Analyzer]

# Create a stream block.
  puts "Configuring stream block ..."
  set hStreamBlock [stc::create streamBlock -under $hPortTx -insertSig true \
  			-frameConfig "" -frameLengthMode FIXED -maxFrameLength 1200 -FixedFrameLength 256]

# Add an EthernetII Protocol Data Unit (PDU).
  puts "Adding headers"
  set hEthernet [stc::create ethernet:EthernetII -under $hStreamBlock -name sb1_eth -srcMac 00:00:20:00:00:00 \
  				-dstMac 00:00:00:00:00:00]

# Use modifier to generate multiple streams.
  puts "Creating Modifier on Stream Block ..."
  set hRangeModifier [stc::create RangeModifier \
          -under $hStreamBlock \
          -ModifierMode DECR \
          -Mask "00:00:FF:FF:FF:FF" \
          -StepValue "00:00:00:00:00:01" \
          -Data "00:00:10:10:00:01" \
          -RecycleCount 20 \
          -RepeatCount 0 \
          -DataType NATIVE \
          -EnableStream true \
          -Offset 0 \
          -OffsetReference "sb1_eth.dstMac"]

# Display stream block information.
  puts "\n\nStreamBlock information"
  set lstStreamBlockInfo [stc::perform StreamBlockGetInfo -StreamBlock $hStreamBlock] 

  foreach {szName szValue} $lstStreamBlockInfo {
    puts \t$szName\t$szValue
  }
  puts \n\n
  

# Configure generator.
  puts "Configuring Generator"
  set hGeneratorConfig [stc::get $hGenerator -children-GeneratorConfig]
  
  stc::config $hGeneratorConfig \
              -DurationMode BURSTS \
  	          -BurstSize 1 \
              -Duration 100 \
  	          -LoadMode FIXED \
  	          -FixedLoad 100 \
              -LoadUnit PERCENT_LINE_RATE \
  	          -SchedulingMode PORT_BASED

# Analyzer Configuration.
  puts "Configuring Analyzer"
  set hAnalyzerConfig [stc::get $hAnalyzer -children-AnalyzerConfig]

# Subscribe to realtime results.
  puts "Subscribe to results"
  stc::subscribe -Parent $hProject \
                -ConfigType Analyzer \
                -resulttype AnalyzerPortResults  \
                -filenameprefix "Analyzer_Port_Results"

  stc::subscribe -Parent $hProject \
                 -ConfigType Generator \
                 -resulttype GeneratorPortResults  \
                 -filenameprefix "Generator_Port_Counter" \
                 -Interval 2

# Configure Capture.
  if { $ENABLE_CAPTURE } {
    puts "\nStarting Capture..."
  
  # Create a capture object. Automatically created.
    set hCapture [stc::get $::hPortRx -children-capture]
    stc::config $hCapture -mode REGULAR_MODE -srcMode TX_RX_MODE  
    stc::perform CaptureStart -captureProxyId $hCapture  
  }

# Apply configuration.  
  puts "Apply configuration" 
  stc::apply

# Save the configuration as an XML file. Can be imported into the GUI.
  puts "\nSave configuration as an XML file."
  stc::perform SaveAsXml

# Start the analyzer and generator.
  puts "Start Analyzer"
  stc::perform AnalyzerStart -AnalyzerList $hAnalyzer
  puts "Current analyzer state [stc::get $hAnalyzer -state]"
    
  puts "Start Generator"
  stc::perform GeneratorStart -GeneratorList $hGenerator
  puts "Current generator state [stc::get $hGenerator -state]"

  puts "Wait 5 seconds ..."
  after 5000

  puts "Current analyzer state [stc::get $hAnalyzer -state]"
  puts "Current generator state [stc::get $hGenerator -state]"
  puts "Stop Analyzer"

# Stop the generator.  
  stc::perform GeneratorStop -GeneratorList $hGenerator

# Stop the analyzer.  
  stc::perform AnalyzerStop -AnalyzerList $hAnalyzer

# Display some statistics.

  puts "Frames Counts:"
# Example of Direct-Descendant Notation ( DDN ) syntax. ( DDN starts with an object reference )  
  puts "\tSignature frames: [ stc::get $hAnalyzer.AnalyzerPortResults(1) -sigFrameCount ]"
  puts "\tTotal frames: [ stc::get $hAnalyzer.AnalyzerPortResults(1) -totalFrameCount ]"

# Example of Descendant-Attribute Notation ( DAN ) syntax. ( using explicit indeces )
  puts "\tMinFrameLength: [ stc::get $hPortRx -Analyzer(1).AnalyzerPortResults(1).minFrameLength ]"
# Notice indexing is not necessary since there is only 1 child.    
  puts "\tMaxFrameLength: [ stc::get $hPortRx -Analyzer.AnalyzerPortResults.maxFrameLength ]"

  if { $ENABLE_CAPTURE } {
    puts "[clock format [clock seconds] -format %m-%d-%Y_%l:%M:%S%p] Retrieving Captured frames..."
    
    stc::perform CaptureStop -captureProxyId $hCapture
    
  # Save captured frames to a file.
    stc::perform CaptureDataSave -captureProxyId $hCapture -FileName "capture.pcap" -FileNameFormat PCAP -IsScap FALSE
    
    puts "Captured frames:\t[stc::get $hCapture -PktCount]"
  }

# Disconnect from chassis, release ports, and reset configuration.
  puts "Release ports and disconnect from chassis"
  stc::perform ChassisDisconnectAll
  stc::perform ResetConfig

# Delete configuration
  puts "Deleting project"
  stc::delete $hProject
} err] } {
	puts "Error caught: $err"
}
