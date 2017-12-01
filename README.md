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
1. Change Betaflight PID/Rates.Tested with 9xpro with last ersky9X firmware and multi STM32 module with custom firmware for sport bidirectional communication.

## How to use:
1. Button  **MENU** short press, change pages PID/Rates pages.
**save page** as the name implied send commands for  saving the new page values to betaflight and **reload** commands for retrieving the values from betaflight.
5. Button **EXIT** long press terminate the script running and you exit on general script screen.
6. Button **LEFT** press is taking you on new screen used only for debugging.This is to be used only by advanced users that know how to modify the script source and configure the debugging test screen for their needs.

