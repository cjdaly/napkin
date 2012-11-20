#!/usr/bin/python
#
# serial port code adapted from this:
#   http://gigamega-micro.googlecode.com/files/serdisplay.py
#

import urllib, urllib2, base64
import sys, time, datetime, array
import serial
import re

# -------------- configurable settings ---------

# settings for UART1
LCD_01 = {'tty': '/dev/ttyO1', 'rx_mux': 'uart1_rxd', 'tx_mux': 'uart1_txd', 'mux_mode': 0}

# settings for UART2
LCD_02 = {'tty': '/dev/ttyO2', 'rx_mux': 'spi0_sclk', 'tx_mux': 'spi0_d0', 'mux_mode': 1}

LCD_NUM_ROWS = 2
LCD_NUM_COLS = 16

# ---------------------------------------------------------

COMMAND_PREFIX = 254
BAUDRATE = 9600
TIMEOUT = 3 # serial port timeout is 3 seconds - only used when reading from display

# MUX settings
RECEIVE_ENABLE = 32

def writeToDisplay(serDisplay, s):
    serDisplay.write(s)
    time.sleep(0.1) # Sparkfun LCD backpack needs pause between commands

def initializeDisplay(lcd):
    # set the RX pin for Mode 0 with receive bit on
    # - use %X formatter, since value written must be in hex (e.g. write "21" for mode 1 with receive enabled = 33)
    open('/sys/kernel/debug/omap_mux/' + lcd['rx_mux'], 'wb').write("%X" % (RECEIVE_ENABLE + lcd['mux_mode']))
    # set the TX pin for Mode 0
    open('/sys/kernel/debug/omap_mux/' + lcd['tx_mux'], 'wb').write("%X" % lcd['mux_mode'])
    serDisplay = serial.Serial(lcd['tty'], BAUDRATE, timeout=TIMEOUT)
    writeToDisplay(serDisplay, "hello")
    time.sleep(1)

    setNumCols(serDisplay, LCD_NUM_COLS)
    setNumRows(serDisplay, LCD_NUM_ROWS)  
    clearScreen(serDisplay)  
    return serDisplay
    
def setCursorPos(serDisplay, row, col, clearRow = False):
    """Position the LCD cursor - row and col are 1-based"""
    offset = 127 + col
    if row == 2:
        offset = 128  + 63 + col
    elif row == 3:
        offset = 128 + 19 + col
    elif row == 4:
        offset = 128 + 83 + col
    cmd = array.array('B', (COMMAND_PREFIX, offset))
    writeToDisplay(serDisplay, cmd.tostring())  
    
def setNumCols(serDisplay, cols):    
    """Tell the serial backpack the number of columns supported by the LCD"""
    cmd = array.array('B', (124,0))
    if (cols == 20):
        cmd[1] = 3
    else:
        if (cols != 16):
            print("WARNING: num columns of %d not valid - must be 16 or 20.  Defaulting to 16", cols)
        cmd[1] = 6        
    writeToDisplay(serDisplay, cmd.tostring())  

    
def setNumRows(serDisplay, rows):
    """Tell the serial backpack the number of rows supported by the LCD"""
    cmd = array.array('B', (124,0))
    if (rows == 4):
        cmd[1] = 5
    else:
        if (rows != 2):
            print("WARNING: num rows of %d not valid - must be 2 or 4.  Defaulting to 2", rows)
        cmd[1] = 6
    writeToDisplay(serDisplay, cmd.tostring())  
 

def clearScreen(serDisplay):
    cmd = array.array('B', (COMMAND_PREFIX, 1))
    writeToDisplay(serDisplay, cmd.tostring())  


def writeLines(line1, line2, serDisplay):
    setCursorPos(serDisplay, 1, 1, True)                
    writeToDisplay(serDisplay, line1)
    #
    setCursorPos(serDisplay, 2, 1, True)                
    writeToDisplay(serDisplay, line2)

def getLineArg(lineNum):
    if (lineNum < len(sys.argv)):
        line = sys.argv[lineNum]
	return line[:LCD_NUM_COLS]
    else:
        return ""

TIME_LINE_MASKS = [
    "%I:%M %a %d %b",
    "%I:%M %a %d.%b",
    "%I:%M %a.%d %b",
    "%I:%M.%a %d %b",
    "%I:%M %a %d %b",
    "%I:%M %a %d*%b",
    "%I:%M %a*%d %b",
    "%I:%M*%a %d %b",
]

def updateLcds(serDisplay1, serDisplay2, cycle, stuff):
    timeNow = time.localtime()
    timeLineMask = TIME_LINE_MASKS[cycle%len(TIME_LINE_MASKS)]
    timeLine = time.strftime(timeLineMask, timeNow)
    timeLine = timeLine[:LCD_NUM_COLS]
    #
    line1 = timeLine
    line2 = getLineArg(1)
    line3 = getLineArg(2)
    line4 = stuff
    #
    writeLines(line1, line2, serDisplay2)
    writeLines(line3, line4, serDisplay1)

#
# Napkin config

DEVICE_ID="bone1"
NAPKIN_URL="http://192.168.2.50:4567"
NAPKIN_CONFIG_URL=NAPKIN_URL + "/config/" + DEVICE_ID
NAPKIN_CHATTER_URL=NAPKIN_URL + "/chatter"
NAPKIN_CONFIG_KEYS =[None, 'test', None, None]

#
# Napkin util

def getConfigValue(key):
    napkinConfigUrl=NAPKIN_CONFIG_URL + "?key=" + key
    request = urllib2.Request(napkinConfigUrl);
    authHeader = base64.encodestring('%s:%s' % (DEVICE_ID, DEVICE_ID)).replace('\n', '')
    request.add_header("Authorization", "Basic %s" % authHeader)
    text = urllib2.urlopen(request).read()
    return text

# postText = "Hello from bone1!\n"
# request = urllib2.Request(napkinChatterUrl, postText)
# request.add_header("Authorization", "Basic %s" % authHeader)
# response = urllib2.urlopen(request)
# print response.read()


#
#
#

serDisplay1 = initializeDisplay(LCD_01)
serDisplay2 = initializeDisplay(LCD_02)

stuff="???"
done=False
cycle=0
while(not done):
    cycle += 1
    if (cycle%8 == 0):
        stuff = getConfigValue('status')
    updateLcds(serDisplay1, serDisplay2, cycle, stuff)
    time.sleep(1)

