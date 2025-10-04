# Garmin Watch Datafield

The repository contains the data field for Garmin usable with Trio system. 

# How to use 

The easy solution is to download the *.prg files for you garmin devices. The files are available here : https://github.com/mountrcg/...

To install the prg in your devices :
- Install Garmin Express and configure with your account
- Attach your watch to computer by USB. You should see your watch as USB-drive then.
- It's usually named "GARMIN" as device (on Mac too, plus it have drive letter in windows, for example, let's say it's drive "E:").
Open your watch storage in Explorer or Finder, enter into folder GARMIN and then in its subfolder APP, so you now should be in path like E:\GARMIN\APPS (on Windows) or /GARMIN/GARMIN/APPS  (on Mac, where first "GARMIN" stands for device name).
- Download any watchface, app, widget with .PRG-file extension format from our file archive you want and put it in that GARMIN/APPS folder.
- You even can download that file directly to yours watch folder from browser, but be sure to finish download before detachment, or you can have broken unfinished file.
- Eject garmin's USB-storage, wait until it writes all caches and only then detach your watch from USB.
- Enter into watch settings and choose ConnectIQ watchface or enable/disable widget or work with that freshly installed app.

# How to compile and adapt the code 

Download the Garmin SDK.
You need to install Visual Studio Code. In it you will need to install the Monkey C plugin. 
Once you have that within Visual Studio Code hit CMD-Shift-P and enter Monkey. You will see all commands for testing and building Garmin apps.
* use `Monkey C: Open SDK Manager` and download all devices and newest SDK release
* use `Monkey C: Generate a Developer Key` and follow instructions
* use `Monkey C: Build for Device` to genrate your own *.prg file to sideload to your watch
* 
More information are available here : https://developer.garmin.com/connect-iq/overview/ 


(c) Copyright I guess Pierre & Ivan 2023
