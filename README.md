# Ersky9x-Tx-bas-scripts
scripts in basic language for control using Tx with ersky9x firmware

## Installing
How to install:
1. Power off your transmitter.
2. Remove the SD card and plug it into a computer
3. Copy the scripts(only the files with extension **.bas**)  to the **/SCRIPTS** folder on the  SD card.If the folder does not exist you have to generate it. See Note: below for more details
4. Reinsert your SD card into the transmitter
5. Power up your transmitter.

- **Note:**

 /SCRIPTS – put standalone scripts here.
 
 /SCRIPTS/TELEMETRY – put scripts that display on the custom telemetry screens here.
 
 /SCRIPTS/MODEL – put “background” scripts here.

## Use
1. Press **Menu** button long.
2. Scroll down on the pop up menu and select **"Run Script"**
3. Scroll down on the script page to the script you want to run.
4. Run the script by pressing **Menu** button  long.

## Scripts
1. Change Betaflight PID/Rates/VTX.Tested with 9xpro with last ersky9X firmware and multi STM32 module with custom firmware for sport bidirectional communication.
2. Configuration of a DIY RX or a JUMPER R8 with new fimrmware.

## How to use(PID/VTX script):
1. Button  **MENU** short press, change pages PID/Rates pages.
2. Button **UP** and **DOWN** move between fields/lines to select value for editing.
3. Button **RIGHT** allow editing the page values the selected value will blink so you know you are on this mode.In this mode press button **UP** and **DOWN** increase /decrease values.Button **EXIT** short press close edititing mode blink will stop.
4. Button  **MENU** long press enters in new  menu(saving) with 2 options **save page** and **reload**. Select one of the options by pressing **UP** and **DOWN** button.Press **RIGHT** button to run the selected mode.
**save page** as the name implied send commands for  saving the new page values to betaflight and **reload** commands for retrieving the values from betaflight.
5. Button **EXIT** long press terminate the script running and you exit on general script screen.
6. Button **LEFT** press is taking you on new screen used only for debugging.This is to be used only by advanced users that know how to modify the script source and configure the debugging test screen for their needs.

## Note:
Added new script DIY_RX_CFG.bas for configuration of a DIY (JUMPER R8) frSky compatible receiver.
For more details about that see:

https://www.rcgroups.com/forums/showthread.php?3420847-DIY-FrSky-X%28D16%29-receiver
https://www.rcgroups.com/forums/showthread.php?3504875-Jumper-R8-Receiver-8-channel-PPM-16-channel-SBUS-D16-LBT-D8-compatible-firmware

The configration modes are:
1. **Page 1: MODES**

1) receiver mode to X(D16)protocol channels 1-8 output PWM.
2) receiver mode to X(D16)protocol channels 1-8 output PWM with no telemetry.
3) receiver mode to X(D16)protocol channels 9-16 output PWM.
4) receiver mode to X(D16)protocol channels 9-16 output PWM with no telemetry.
5) receiver mode to D(D8)protocol (with Hub telemetry).
6) receiver mode to LBT protocol.
7) receiver mode for servo rate(selection- 22.5;18;9-ms)-at the moment 9ms rate is not implemented yet
8) receiver mode SBUS(inverted signal or not)-not implemented yet.
9) receiver mode SPORT(inverted signal or not)-not tested.

2. **Page 2: STATISTICS**

1) DropPkt 
2) Drop%
3) TotCrcErr
4) LbtBlks
5) PktErr

## How to use(DIY RX script):
1. Button  **MENU** short press, change pages between RX-MODES page and Statistics.
2. Button **UP** and **DOWN** move between fields/lines to select value for editing.
3. Button **RIGHT** allow editing the page values the selected value will blink so you know you are on this mode.In this mode press button **UP** and **DOWN** increase /decrease values.Button **LEFT** short press close edititing mode blink will stop.
4. Button  **MENU** long press enters in new  menu(saving) with 2 options **save page** and **reload**. Select one of the options by pressing **UP** and **DOWN** button.Press **RIGHT** button to run the selected mode.
**save page** as the name implied send commands for  saving the new page values to betaflight and **reload** commands for retrieving the values from betaflight.
5. Button **EXIT** long press terminate the script running and you exit on general script screen.
6. Button **LEFT** press is taking you on new screen used only for debugging.This is to be used only by advanced users that know how to modify the script source and configure the debugging test screen for their needs.
