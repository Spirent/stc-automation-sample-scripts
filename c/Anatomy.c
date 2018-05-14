// Copyright (c) 2013 by Spirent Communications, Inc.
// All Rights Reserved
//
// By accessing or executing this software, you agree to be bound 
// by the terms of this agreement.
// 
// Redistribution and use of this software in source and binary forms,
// with or without modification, are permitted provided that the 
// following conditions are met:
//   1.  Redistribution of source code must contain the above copyright 
//       notice, this list of conditions, and the following disclaimer.
//   2.  Redistribution in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer
//       in the documentation and/or other materials provided with the
//       distribution.
//   3.  Neither the name Spirent Communications nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//
// This software is provided by the copyright holders and contributors 
// [as is] and any express or implied warranties, including, but not 
// limited to, the implied warranties of merchantability and fitness for
// a particular purpose are disclaimed.  In no event shall Spirent
// Communications, Inc. or its contributors be liable for any direct, 
// indirect, incidental, special, exemplary, or consequential damages
// (including, but not limited to: procurement of substitute goods or
// services; loss of use, data, or profits; or business interruption)
// however caused and on any theory of liability, whether in contract, 
// strict liability, or tort (including negligence or otherwise) arising
// in any way out of the use of this software, even if advised of the
// possibility of such damage.

// File Name:                 Anatomy.c
// Description:               This script demonstrates basic features 
//                            such as creating streams, generating traffic,
//                            enabling capture, saving realtime results
//                            to files, and retrieving results.

#include <stdio.h>
#include "stccapi.h"

#ifdef __unix__
# include <unistd.h>
#elif defined _WIN32
# include <windows.h>
#define sleep(x) Sleep(1000 * x)
#endif

const char* get_state(const char* handle)
{	
	stccapi_str_vector_t* ret_vec;
	const char* state;

	stccapi_str_vector_t* props = stccapi_str_vector_create();
	stccapi_str_vector_append(props, "state");
	ret_vec = stccapi_get(handle, props);
	state = stccapi_str_vector_get_item(ret_vec, 0);
	stccapi_str_vector_delete(props);
	return state;	
}

int main()
{
	const int ENABLE_CAPTURE = 1;
	
    const char* tx_port_loc = "//10.29.0.58/1/1";
	const char* rx_port_loc = "//10.29.0.96/1/1";
	
	stccapi_str_vector_t* ret_vec;
	const char* h_project;
	const char* h_port_tx;
	const char* h_port_rx;
	const char* h_generator;
	const char* h_analyzer;	
	const char* h_stream_block;
	const char* h_range_modifier;
	const char* h_generator_config;
	const char* h_analyzer_config;
	const char* h_capture;
	const char* sig_frame_count;
    const char* total_frame_count;
	const char* min_frame_length;
	const char* max_frame_length;
	char h_analyzer_port_results[256];	

	// Report the STC version.
	stccapi_str_vector_t* props = stccapi_str_vector_create();
	// Create property name/value pairs
	stccapi_str_vector_append(props, "version");
	ret_vec = stccapi_get("system1", props);
	printf("SpirentTestCenter system version:\t%s\n", stccapi_str_vector_get_item(ret_vec, 0));
			
	// Create the root project object
	printf("Creating project ...\n");
	stccapi_str_vector_delete(props);
	props = stccapi_str_vector_create();	
	stccapi_str_vector_append(props, "under");
	stccapi_str_vector_append(props, "system1");
	h_project = stccapi_create("project", props);

	// Create ports
	printf("Creating ports ...\n");
    stccapi_str_vector_delete(props);
	props = stccapi_str_vector_create();
	
	stccapi_str_vector_append(props, "under");
	stccapi_str_vector_append(props, h_project);
	stccapi_str_vector_append(props, "location");
	stccapi_str_vector_append(props, tx_port_loc);
	stccapi_str_vector_append(props, "useDefaultHost");
	stccapi_str_vector_append(props, "false");
	h_port_tx = stccapi_create("port", props);

	stccapi_str_vector_delete(props);
	props = stccapi_str_vector_create();
	stccapi_str_vector_append(props, "under");
	stccapi_str_vector_append(props, h_project);
	stccapi_str_vector_append(props, "location");
	stccapi_str_vector_append(props, rx_port_loc);
	stccapi_str_vector_append(props, "useDefaultHost");
	stccapi_str_vector_append(props, "false");		
	h_port_rx = stccapi_create("port", props);

	// Configure ethernet Fiber interface.
	stccapi_str_vector_delete(props);
	props = stccapi_str_vector_create();
	stccapi_str_vector_append(props, "under");
	stccapi_str_vector_append(props, h_port_tx);
	stccapi_create("EthernetCopper", props);	

	// Attach ports. 
    // Connects to chassis, reserves ports and sets up port mappings all in one step.
    // By default, connects to all previously created ports.
	printf("Attaching ports %s %s\n", tx_port_loc, rx_port_loc);	
	stccapi_perform("AttachPorts", stccapi_str_vector_create());

	// Apply the configuration.
	printf("Apply configuration\n");
	stccapi_apply();

	// Initialize generator/analyzer.
	stccapi_str_vector_delete(props);
	props = stccapi_str_vector_create();
	stccapi_str_vector_append(props, "children-Generator");
	ret_vec = stccapi_get(h_port_tx, props);
	h_generator = stccapi_str_vector_get_item(ret_vec, 0);
			
	printf("Stopping Generator - current state %s\n", get_state(h_generator));
	stccapi_str_vector_delete(props);
	props = stccapi_str_vector_create();
	stccapi_str_vector_append(props, "GeneratorList");
	stccapi_str_vector_append(props, h_generator);
	stccapi_perform("GeneratorStop", props);
	
	stccapi_str_vector_delete(props);
	props = stccapi_str_vector_create();
	stccapi_str_vector_append(props, "children-Analyzer");
	ret_vec = stccapi_get(h_port_rx, props);
	h_analyzer = stccapi_str_vector_get_item(ret_vec, 0);
	
	printf("Stopping Analyzer - current state %s\n", get_state(h_analyzer));
	stccapi_str_vector_delete(props);
	props = stccapi_str_vector_create();
	stccapi_str_vector_append(props, "AnalyzerList");
	stccapi_str_vector_append(props, h_analyzer);
	stccapi_perform("AnalyzerStop", props);
		
	// Create a stream block. FrameConfig with blank double quotes clears the frame out.
	printf("Configuring stream block ...\n");
	stccapi_str_vector_delete(props);
	props = stccapi_str_vector_create();
	stccapi_str_vector_append(props, "under");
	stccapi_str_vector_append(props, h_port_tx);
	stccapi_str_vector_append(props, "insertSig");
	stccapi_str_vector_append(props, "true");
	stccapi_str_vector_append(props, "frameConfig");
	stccapi_str_vector_append(props, "");
	stccapi_str_vector_append(props, "frameLengthMode");
    stccapi_str_vector_append(props, "FIXED");
	stccapi_str_vector_append(props, "maxFrameLength");
	stccapi_str_vector_append(props, "1200");
	stccapi_str_vector_append(props, "fixedFrameLength");
	stccapi_str_vector_append(props, "256");				
	h_stream_block = stccapi_create("streamBlock", props);

	// Add an EthernetII Protocol Data Unit (PDU).
	printf("Adding headers\n");
	stccapi_str_vector_delete(props);
	props = stccapi_str_vector_create();
	stccapi_str_vector_append(props, "under");
	stccapi_str_vector_append(props, h_stream_block);
	stccapi_str_vector_append(props, "name");
	stccapi_str_vector_append(props, "sb1_eth");
	stccapi_str_vector_append(props, "srcMac");
	stccapi_str_vector_append(props, "00:00:20:00:00:00");
	stccapi_str_vector_append(props, "dstMac");
	stccapi_str_vector_append(props, "00:00:00:00:00:00");
	stccapi_create("ethernet:EthernetII", props);			

	// Use modifier to generate multiple streams.
	printf("Creating Modifier on Stream Block ...\n");
	stccapi_str_vector_delete(props);
	props = stccapi_str_vector_create();
	stccapi_str_vector_append(props, "under");
	stccapi_str_vector_append(props, h_stream_block);
	stccapi_str_vector_append(props, "ModifierMode");
	stccapi_str_vector_append(props, "INCR");
	stccapi_str_vector_append(props, "Mask");
	stccapi_str_vector_append(props, "0000FFFFFFFF");
	stccapi_str_vector_append(props, "StepValue");
	stccapi_str_vector_append(props, "000000000001");
	stccapi_str_vector_append(props, "Data");
	stccapi_str_vector_append(props, "000000000000");
	stccapi_str_vector_append(props, "RecycleCount");
	stccapi_str_vector_append(props, "4294967295");
	stccapi_str_vector_append(props, "RepeatCount");
	stccapi_str_vector_append(props, "0");
	stccapi_str_vector_append(props, "DataType");
	stccapi_str_vector_append(props, "BYTE");
	stccapi_str_vector_append(props, "EnableStream");
	stccapi_str_vector_append(props, "FALSE");
	stccapi_str_vector_append(props, "Offset");
	stccapi_str_vector_append(props, "0");
	stccapi_str_vector_append(props, "OffsetReference");
	stccapi_str_vector_append(props, "sb1_eth.dstMac");
	h_range_modifier = stccapi_create("RangeModifier", props);												

	// Configure generator
	printf("Configuring Generator\n");
	stccapi_str_vector_delete(props);
	props = stccapi_str_vector_create();
	stccapi_str_vector_append(props, "children-GeneratorConfig");	
	ret_vec = stccapi_get(h_generator, props);
	h_generator_config = stccapi_str_vector_get_item(ret_vec, 0);

	stccapi_str_vector_delete(props);
	props = stccapi_str_vector_create();
	stccapi_str_vector_append(props, "DurationMode");	
	stccapi_str_vector_append(props, "SECONDS");	
	stccapi_str_vector_append(props, "BurstSize");	
	stccapi_str_vector_append(props, "1");	
	stccapi_str_vector_append(props, "LoadMode");	
	stccapi_str_vector_append(props, "FIXED");	
	stccapi_str_vector_append(props, "FixedLoad");	
	stccapi_str_vector_append(props, "25");	
	stccapi_str_vector_append(props, "LoadUnit");	
	stccapi_str_vector_append(props, "PERCENT_LINE_RATE");	
	stccapi_str_vector_append(props, "SchedulingMode");	
	stccapi_str_vector_append(props, "PORT_BASED");
	stccapi_config(h_generator_config, props);				

	// Analyzer Configuration
	printf("Configuring Analyzer\n");
	stccapi_str_vector_delete(props);
	props = stccapi_str_vector_create();
	stccapi_str_vector_append(props, "children-AnalyzerConfig");	
	ret_vec = stccapi_get(h_analyzer, props);
	h_analyzer_config = stccapi_str_vector_get_item(ret_vec, 0);	

	// Subscribe to realtime results
	printf("Subscribe to results\n");
	stccapi_str_vector_delete(props);
	props = stccapi_str_vector_create();
	stccapi_str_vector_append(props, "Parent");	
	stccapi_str_vector_append(props, h_project);	
	stccapi_str_vector_append(props, "ConfigType");	
	stccapi_str_vector_append(props, "Analyzer");	
	stccapi_str_vector_append(props, "resulttype");	
	stccapi_str_vector_append(props, "AnalyzerPortResults");	
	stccapi_str_vector_append(props, "filenameprefix");	
	stccapi_str_vector_append(props, "Analyzer_Port_Results");	
	stccapi_subscribe(props);

	stccapi_str_vector_delete(props);
	props = stccapi_str_vector_create();
	stccapi_str_vector_append(props, "Parent");	
	stccapi_str_vector_append(props, h_project);	
	stccapi_str_vector_append(props, "ConfigType");	
	stccapi_str_vector_append(props, "Generator");	
	stccapi_str_vector_append(props, "resulttype");	
	stccapi_str_vector_append(props, "GeneratorPortResults");	
	stccapi_str_vector_append(props, "filenameprefix");	
	stccapi_str_vector_append(props, "Generator_Port_Counter");	
	stccapi_subscribe(props);						

	// Configure Capture.	
	if (ENABLE_CAPTURE)
	{
		printf("\nStarting Capture...\n");
  
		// Configure a capture object. Automatically created.
		stccapi_str_vector_delete(props);
		props = stccapi_str_vector_create();
		stccapi_str_vector_append(props, "children-capture");	
		ret_vec = stccapi_get(h_port_rx, props);
		h_capture = stccapi_str_vector_get_item(ret_vec, 0);	

		stccapi_str_vector_delete(props);
		props = stccapi_str_vector_create();
		stccapi_str_vector_append(props, "mode");	
		stccapi_str_vector_append(props, "REGULAR_MODE");	
		stccapi_str_vector_append(props, "srcMode");	
		stccapi_str_vector_append(props, "TX_RX_MODE");	
		stccapi_config(h_capture, props);

		stccapi_str_vector_delete(props);
		props = stccapi_str_vector_create();
		stccapi_str_vector_append(props, "captureProxyId");	
		stccapi_str_vector_append(props, h_capture);	
		stccapi_perform("CaptureStart", props);						
	}

	// Apply configuration.  
	printf("Apply configuration\n");
	stccapi_apply();

	// Save the configuration as an XML file for later import into the GUI.
	printf("\nSave configuration as an XML file.\n");
	stccapi_perform("SaveAsXml", stccapi_str_vector_create());	

	// Start the analyzer and generator.
	printf("Start Analyzer\n");
	stccapi_str_vector_delete(props);
	props = stccapi_str_vector_create();
	stccapi_str_vector_append(props, "AnalyzerList");	
	stccapi_str_vector_append(props, h_analyzer);
	stccapi_perform("AnalyzerStart", props);	
	printf("Current analyzer state %s\n", get_state(h_analyzer));

	sleep(2);
	
	printf("Start Generator\n");
	stccapi_str_vector_delete(props);
	props = stccapi_str_vector_create();
	stccapi_str_vector_append(props, "GeneratorList");
	stccapi_str_vector_append(props, h_generator);
	stccapi_perform("GeneratorStart", props);		
	printf("Current generator state %s\n", get_state(h_generator));

	printf("Wait 5 seconds ...\n");
	sleep(5);
	
	printf("Current analyzer state %s\n", get_state(h_analyzer));
	printf("Current generator state %s\n", get_state(h_generator));	
	
	// Stop the analyzer. 
	printf("Stop Analyzer\n");
	stccapi_str_vector_delete(props);
	props = stccapi_str_vector_create();
	stccapi_str_vector_append(props, "AnalyzerList");
	stccapi_str_vector_append(props, h_analyzer);
	stccapi_perform("AnalyzerStop", props);	
	sleep(1);
	
	// Display some statistics.
	printf("Frames Counts:\n");
	stccapi_str_vector_delete(props);
	props = stccapi_str_vector_create();
	stccapi_str_vector_append(props, "sigFrameCount");	
	// Example of Direct-Descendant Notation ( DDN ) syntax. ( DDN starts with an object reference )  
	sprintf(h_analyzer_port_results, "%s.AnalyzerPortResults(1)", h_analyzer);
	ret_vec = stccapi_get(h_analyzer_port_results, props);
	sig_frame_count = stccapi_str_vector_get_item(ret_vec, 0);

	stccapi_str_vector_delete(props);
	props = stccapi_str_vector_create();
	stccapi_str_vector_append(props, "totalFrameCount");
	ret_vec = stccapi_get(h_analyzer_port_results, props);
	total_frame_count = stccapi_str_vector_get_item(ret_vec, 0);
	    	
	printf("\tSignature frames: %s\n", sig_frame_count);
	printf("\tTotal frames: %s\n", total_frame_count);

	stccapi_str_vector_delete(props);
	props = stccapi_str_vector_create();
	// Example of Descendant-Attribute Notation ( DAN ) syntax. ( using explicit indeces )
	stccapi_str_vector_append(props, "Analyzer(1).AnalyzerPortResults(1).minFrameLength");	
	ret_vec = stccapi_get(h_port_rx, props);
	min_frame_length = stccapi_str_vector_get_item(ret_vec, 0);	
	printf("\tMinFrameLength: %s\n", min_frame_length);

	stccapi_str_vector_delete(props);
	props = stccapi_str_vector_create();	
	// Notice indexing is not necessary since there is only 1 child. 
	stccapi_str_vector_append(props, "Analyzer.AnalyzerPortResults.maxFrameLength");	
	ret_vec = stccapi_get(h_port_rx, props);
	max_frame_length = stccapi_str_vector_get_item(ret_vec, 0);	
	printf("\tMaxFrameLength: %s\n", max_frame_length);	

	if (ENABLE_CAPTURE)
	{
		printf("Retrieving Captured frames...\n");

		stccapi_str_vector_delete(props);
		props = stccapi_str_vector_create();
		stccapi_str_vector_append(props, "captureProxyId");
		stccapi_str_vector_append(props, h_capture);
		stccapi_perform("CaptureStop", props);
				   
		// Save captured frames to a file.		
		stccapi_str_vector_append(props, "captureProxyId");
		stccapi_str_vector_append(props, h_capture);
		stccapi_str_vector_append(props, "FileName");
		stccapi_str_vector_append(props, "capture.pcap");
		stccapi_str_vector_append(props, "FileNameFormat");
		stccapi_str_vector_append(props, "PCAP");
		stccapi_str_vector_append(props, "IsScap");
		stccapi_str_vector_append(props, "FALSE");
		stccapi_perform("CaptureDataSave", props);
								
		stccapi_str_vector_delete(props);
		props = stccapi_str_vector_create();
		stccapi_str_vector_append(props, "PktCount");
		ret_vec = stccapi_get(h_capture, props);				
		printf("Captured frames:\t%s\n", stccapi_str_vector_get_item(ret_vec, 0));
	}

	// Disconnect from chassis, release ports, and reset configuration.
	printf("Release ports and disconnect from chassis.\n");
	stccapi_perform("ChassisDisconnectAll", stccapi_str_vector_create());	
	stccapi_perform("ResetConfig", stccapi_str_vector_create());	
		
	// Delete configuration
	printf("Deleting project\n");
	stccapi_delete(h_project);	

	return 0;
}

