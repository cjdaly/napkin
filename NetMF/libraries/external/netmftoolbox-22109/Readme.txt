This is a compilation of .NET Micro Framework libraries.
All drivers are written in Visual C# 2010 but since Netduino is also open to the Visual Basic community, there are code samples for VB2010 as well.

The compilation contains a few folders:
- Framework: The library sourcecode can be found here
- Installer: Tools to build the installer
- Release (4.1): This folder contains the latest DLL of the framework for the .NET Micro Framework 4.1
- Release (4.2): This folder contains the latest DLL of the framework for the .NET Micro Framework 4.2
- Release (4.3): This folder contains the latest DLL of the framework for the .NET Micro Framework 4.3
- Samples: Contains samples to work with the library for both VB and C#
- Schematics: Fritzing schematics and PDFs used for the samples. Download Fritzing at www.fritzing.org

If you like to see some more documentation, see http://netmftoolbox.codeplex.com/documentation

Current samples:
- 7-Segment counter: Counting from 0 to 9 with a 7-segment display and 74HC595 IC
- Adafruit Fridgelogger: The Fridge Logger demonstration for Netduino
- Adafruit Motor Control Shield: Drives 4 DC motors and 2 servos
- Adafruit GPS Logger: Logging GPS data to an SD card
- Auto-Repeat Button: A great way to handle buttons
- Bar Graph Breakout Kit: A sample for Sparkfun's Bar Graph Breakout Kit
- Basic Speaker: An easy way to drive a PC-speaker and output monophonic sounds
- BitBang Buzzer: When all PWM-pins are occupied and you want to add a buzzer, check this!
- BlinkM Demo: A small demo for the BlinkM RGB LED module
- DS1307 RTC Module: Preserving time when powered off
- Dangershield: Have got the shield? Here's a sample code for NETMF
- DFRobot Motorshield: A sample for the L298N and L293 DFRobot motorshields
- EL Escudo Dos Shield: Samplecode for driving 8 EL-wires with the EL Escudo Dos Shield
- H-Bridge Motor Driver: Driving two DC motors using a H-bridge DC motordriver
- HD44780 LCD: A very simple and short HD44780 example
- Hd44780Lcd Snake: A simple game that demonstrates custom characters on a HD44780 LCD
- IntegratedSocket sample: Requesting a web page with the integrated .NETMF TCP socket
- IRC Client: Connecting your device to an IRC server
- Joystick Shield: A sample for the famous joystick shield
- LED RingCoder Breakout: Sample for Sparkfun's LED RingCoder Breakout board
- LoL Shield: A sample code for the 'Lots of Leds' shield (requires a fast MCU!)
- RGB LED Strip: Some nice animations on LPD8806 and WS2801-based RGB strips
- Matrix KeyPad: Using a matrix keypad
- Micro Serial Servo Controller: Using the pololu serial servo controller with a .NET Microcontroller
- Multiplexing GPIOs: Expanding the amount of GPIO ports by adding 74HC595 and/or 74HC165 IC's
- NES Controller Adapter Sample: Using two NES controllers
- NMEA GPS Device: Find out where your .NETMF has been
- POP3 Client: Reading your mailbox with a networking-enabled device
- Rdm630 RFID Reader: Reading RFID tags with a Rdm630 breakout board
- RGB Led: Using 'HTML-like' hex-numbers to drive an RGB-led
- Rotary DIP Switch: Using binary rotary DIP switches
- Rotary Encoder: A plain rotary encoder
- Sharp GP2Y0A02YK Proximity Sensor: A cheap sensor to measure distance, not very accurate
- SMTP Client: Sending mail through your ISP's SMTP-server
- SNTP Client: Synchronizing the Netduino with SNTP
- Sound Module: Using the 4D Systems SOMO-14D sound module
- Sparkfun Ardubot: Code sample for the Sparkfun Ardubot PCB
- Terminal Server: Advanced Telnet server with file system access, etc.
- Thermal Printer: Sample code for using a thermal printer
- Thumb joystick: A simple piece of code for the popular Sparkfun Thumb Joystick
- TMP36 Temperature sensor: A temperature sensor in celcius, fahrenheit and kelvin
- Wearable Keypad: A driver for Sparkfun's Wearable Keypad
- Web client: Requesting the latest headers from Cnn.com over HTTP
- WiFly Socket: Creating sockets with a WiFly module
- Wii Nunchuk: Using the Nintendo Wii Nunchuk as controller for your device

The library is maintained by Stefan Thoolen with a lot of thanks from:
- Steven Don for his help with writing Speaker.cs and his C# expertise
- Mario Vernari for his contributions and help with understanding electronics
- Daniel Loughmiller for the 74HC595 bitbang code
- Chris Walker for a lot of guidance and appreciating and spreading these works
- Matt Isenhower and Steve Bulgin for helping with the installer
- The Netduino Community for if they weren't using this, I wouldn't continue expanding this
