# obs-highlighter-plugin

This plugin allows you to mark important moments of the broadcast by pressing a hotkey.
The time is recorded in the file relative to the start of the broadcast. 

To get started, save the `highliht.lua` file to your local disk and add it to OBS via the menu `Tools -> Scripts`. After that, you need to set the output directory in the script settings for saving files with markup. 

After script loading in the OBS settings (`File -> Settings -> Hotkeys`), a hotkey setting for marking important events (`Mark/highlight event hotkey`) will appear.
This hotkey need to be set. 


If everything is done correctly, after the start of recording/broadcasting, a file named `record_xxx` for recording and` stream_xxx` for broadcasting will be created in the specified directory, where `xxx` is the date and time of the beginning of recording/broadcasting. 