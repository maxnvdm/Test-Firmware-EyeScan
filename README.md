The information below describes the operation of and interaction with the newly developed eye scan firmware. This firmware has been integrated into the EoS testbench firmware developed by DESY for operation on a Kintex 7 FPGA.

The modules I developed and added to this project are:
* [eyeScan.v](https://gitfront.io/r/user-6751004/1d277caa20836c40b5fe4b1442b3af027a15e8d9/Test-Firmware-EyeScan/blob/firmware%20code/eyeScan.v) - the primary module responsible for interacting the GTX transceiver and performing the eye scan.
* [eyeScan_tb.vhd](https://gitfront.io/r/user-6751004/1d277caa20836c40b5fe4b1442b3af027a15e8d9/Test-Firmware-EyeScan/blob/sim_2/new/eyeScan_tb.vhd) - the testbench used to simulate the eye scan process and verify various operations are working correctly.

The modules I contributed to or modified to support the eye scan functionality:
* [GetEyeScanData.vhd](https://gitfront.io/r/user-6751004/1d277caa20836c40b5fe4b1442b3af027a15e8d9/Test-Firmware-EyeScan/blob/firmware%20code/GetEyeScanData.vhd) - the module responsible for transfering the eye scan data out of the FPGA over UART to the control PC.
* [EyeScanStatus.vhd](https://gitfront.io/r/user-6751004/1d277caa20836c40b5fe4b1442b3af027a15e8d9/Test-Firmware-EyeScan/blob/firmware%20code/EyeScanStatus.vhd) - the module responsible for interacting with the eye scan firmware, used for monitoring and control.
* [GTX_RxTx_dual.vhd](https://gitfront.io/r/user-6751004/1d277caa20836c40b5fe4b1442b3af027a15e8d9/Test-Firmware-EyeScan/blob/firmware%20code/GTX_RxTx_dual.vhd) - the module responsible for instantiating the GTX and eye scan firmware.
* [LPGBT_BERTest_KC705.vhd](https://gitfront.io/r/user-6751004/1d277caa20836c40b5fe4b1442b3af027a15e8d9/Test-Firmware-EyeScan/blob/firmware%20code/LPGBT_BERTest_KC705.vhd) - the top-level module responsible for instantiating all other firmware and setting up the interconnections between modules. 
* [LPGBT_BERTest_KC705.xdc](https://gitfront.io/r/user-6751004/1d277caa20836c40b5fe4b1442b3af027a15e8d9/Test-Firmware-EyeScan/blob/constrs_1/LPGBT_BERTest_KC705.xdc) - the constraints file where various properties are set to enable the eye scan functionality.

## Documentation of the Eye Scan Module
V1, 20 May 2021

Max Nikoi van der Merwe

This document describes how to interact with the eye scan module and the data required to produce a BER eye diagram. The signals involved have been divided into control signals and data signals. The control signals are used to set configuration parameters and operate the eye scan module. The data signals are used to transfer the eye scan data out of the module. 

*Table 1: Eye scan control signals*

|**Signal**|**Size (bits)**|**Description**|
| :- | :- | :- |
|Max\_Prescale|5|Set to a value (0 to 31) before starting eye scan. Determines the resolution/time taken for the scan. Set to 0 for the fastest scan.|
|RunScan|1|Set to ‘1’ to start the eye scan. Must be set to ‘0’ before being able to start a new scan.|
|ScanComplete|1|Equals ‘1’ when the eye scan is finished. Equals ‘0’ when starting a new scan.|
|GetData\_eye\_req|1|Set to ‘1’ when eye scan data should be readout from BRAM. Should only be set after the scan is completed.|
|GetData\_eye\_rdy|1|Equals ‘1’ when output signals have been loaded with BRAM data. Equals ‘0’ when output signals are still being filled.|
|GetData\_eye\_nxt|1|Set to ‘1’ to start reading the next 496 bytes from BRAM.|
|GetData\_eye\_cmplt|1|Equals ‘1’ when all the BRAM data has been readout.|

The eye scan data signals are all 124 bytes wide. This size was chosen based on the maximum UART frame size (508 bytes) and to not split pixel data (each pixel uses 8 bytes). The maximum amount of data output from an eye scan is 265,200 bytes. This amount can vary based on configuration settings. Eye scan data is stored in BRAM while the scan is run. This data can then be readout after the scan using the data signals and the readout process described on the next page.

*Table 2: Eye scan data signals*

|**Signals**|**Size (bits)**|**Description**|
| :- | :- | :- |
|GetData\_eye\_vertical|992|Vertical offset and misc. info of eye scan pixels (62 x 16 bit)|
|GetData\_eye\_horizontal|992|Horizontal offset of eye scan pixels (62 x 16 bit)|
|GetData\_eye\_samples|992|Sample count for eye scan pixels (62 x 16 bit)|
|GetData\_eye\_errors|992|Error count for eye scan pixels (62 x 16 bit)|
Process for running an eye scan:

1. Max\_Prescale should be set to the desired value (nominal value is 6).
1. RunScan should be set to ‘1’.
1. ScanComplete will be set to ‘1’ when the scan has finished. 

RunScan must be set to ‘0’ before being able to start a new scan.

Process for reading out eye scan data:

1. GetData\_eye\_req should be set to ‘1’ to start the readout from BRAM. 
1. GetData\_eye\_rdy will be set to ‘1’ when the output signals (GetData\_eye\_vertical, GetData\_eye\_horizontal, GetData\_eye\_samples, GetData\_eye\_errors) have been loaded with data from BRAM.
1. GetData\_eye\_nxt should be set to ‘1’ when the output signals have been read and new data should be fetched from BRAM. 
1. GetData\_eye\_rdy will be set to ‘0’ while the output signals are loaded with data from BRAM.
1. GetData\_eye\_nxt should be set to ‘0’.
1. GetData\_eye\_rdy will be set to ‘1’ when the output signals have been loaded with data from BRAM.
1. GetData\_eye\_nxt should be set to ‘1’ when the output signals have been read and new data should be fetched from BRAM.
1. Repeat step 3 to 6 until GetData\_eye\_cmplt is set to ‘1’ indicating all BRAM data has been read.



This process is illustrated in the sequence diagram on the following page, Figure 1.

![](Aspose.Words.bb359b26-8c3d-42f9-a0be-acb810c797ea.001.png)




*Figure 1: Sequence diagram illustrating how to start the scan and readout data from the eye scan module.*


Each pixel making up the eye diagram is described by the parameters in the table below.

*Table 3: Description of eye scan data*

|**Parameter**|**Range**|**Size**|**Description**|
| :- | :- | :- | :- |
|Vertical offset|127 to -127|7 bits|Vertical offset counts for current pixel measurement.|
|Horizontal offset|32 to -32|11 bits|Horizontal offset counts for current pixel measurement.|
|Errors|0 to 65535|16 bits|Accumulated error count.|
|Samples|0 to 65535|16 bits|Accumulated sample count, scaled by prescale and bus width.|
|Prescale|0 to 31|5 bits|Value used to scale sample count. Actual bits sampled equals sample\_count × bus\_width × 2^(1+prescale).|
|UT sign|0 or 1|1 bit|Equalizer threshold, need to accumulate samples and errors for each pixel at 0 and 1.|


The data signals hold 62 pixels worth of data. Each pixel in the data signal has its data represented as seen in the table below.

*Table 4: Data composition for one pixel*

|**Parameter**|**Size**|
| :- | :- |
|{ 5'b Prescale, 2'b00, 1'b UTsign, 1'b OffsetSign, 7'b VertOffset }|16 bits|
|{ 5’b00000, 11'b HorizontalOffset }|16 bits|
|{ 16'b Samples }|16 bits|
|{ 16'b Errors }|16 bits|





4

