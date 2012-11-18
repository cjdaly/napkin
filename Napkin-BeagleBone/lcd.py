#!/usr/bin/python
#
# adapted from this source:
#   http://gigamega-micro.googlecode.com/files/serdisplay.py
#

import sys, time, datetime, array
import serial
from threading import Thread
import logging
import re

# -------------- configurable settings ---------

# settings for UART1
# DISPLAYPORT = '/dev/ttyO1'
# RX_MUX = 'uart1_rxd'
# TX_MUX = 'uart1_txd'
# MUX_MODE = 0

# settings for UART2
DISPLAYPORT = '/dev/ttyO2'
RX_MUX = 'spi0_sclk'
TX_MUX = 'spi0_d0'
MUX_MODE = 1

# settings for Serial LCD
#DISPLAY_TYPE = 'SPARKFUN_KIT'
DISPLAY_TYPE = 'SPARKFUN'

LCD_NUM_ROWS = 2
LCD_NUM_COLS = 16

# determines whether debug info is written to the console
Debug = True

# ---------------------------------------------------------

COMMAND_PREFIX = 254
BAUDRATE = 9600
TIMEOUT = 3 # serial port timeout is 3 seconds - only used when reading from display

# MUX settings
RECEIVE_ENABLE = 32

serDisplay = None 
lastUpdateTime = datetime.datetime.now()

numRows = 0
numCols = 0

lastBrightness = 9999


def writeToDisplay(s):
    serDisplay.write(s)
    time.sleep(0.1) # Sparkfun LCD backpack needs pause between commands

def initializeDisplay(rows, cols):
    global serDisplay
    # set the RX pin for Mode 0 with receive bit on
    # - use %X formatter, since value written must be in hex (e.g. write "21" for mode 1 with receive enabled = 33)
    open('/sys/kernel/debug/omap_mux/' + RX_MUX, 'wb').write("%X" % (RECEIVE_ENABLE + MUX_MODE))
    # set the TX pin for Mode 0
    open('/sys/kernel/debug/omap_mux/' + TX_MUX, 'wb').write("%X" % MUX_MODE)
    
    serDisplay = serial.Serial(DISPLAYPORT, BAUDRATE, timeout=TIMEOUT)
    writeToDisplay("hello")
    time.sleep(1)

    setNumCols(cols)
    setNumRows(rows)  
    clearScreen()  
    
def setCursorPos(row, col, clearRow = False):
    """Position the LCD cursor - row and col are 1-based"""
    if clearRow and DISPLAY_TYPE != 'SPARKFUN':
        # clear the row by writing blanks to all columns in the row
        # move to start of row 
        cmd = array.array('B', (COMMAND_PREFIX, 128, (row - 1) * numCols))        
        writeToDisplay(cmd.tostring())   
        writeToDisplay(' ' * numCols)   
    if DISPLAY_TYPE == 'SPARKFUN':
        offset = 127 + col
        if row == 2:
            offset = 128  + 63 + col
        elif row == 3:
            offset = 128 + 19 + col
        elif row == 4:
            offset = 128 + 83 + col
        if Debug:
            print("setting cursor pos for Sparkfun " + str(offset))
        cmd = array.array('B', (COMMAND_PREFIX, offset))
    else:        
        cmd = array.array('B', (COMMAND_PREFIX, 128, (row - 1) * numCols + col - 1))
    writeToDisplay(cmd.tostring())  
    
def setNumCols(cols):    
    """Tell the serial backpack the number of columns supported by the LCD"""
    global numCols    
    numCols = cols
    if DISPLAY_TYPE == 'SPARKFUN':
        cmd = array.array('B', (124,0))
    else:
        cmd = array.array('B', (COMMAND_PREFIX,0))
    if (numCols == 20):
        cmd[1] = 3
    else:
        if (numCols != 16):
            print("WARNING: num columns of %d not valid - must be 16 or 20.  Defaulting to 16", numCols)
            numCols = 16
        cmd[1] = 6        
    writeToDisplay(cmd.tostring())   

    
def setNumRows(rows):
    """Tell the serial backpack the number of rows supported by the LCD"""
    global numRows
    numRows = rows  
    if DISPLAY_TYPE == 'SPARKFUN':
        cmd = array.array('B', (124,0))
    else:
        cmd = array.array('B', (COMMAND_PREFIX,0))
    if (numRows == 4):
        cmd[1] = 5
    else:
        if (numRows != 2):
            print("WARNING: num rows of %d not valid - must be 2 or 4.  Defaulting to 2", numRows)
            numRows = 2
        cmd[1] = 6
    writeToDisplay(cmd.tostring()) 
 

def setBrightness(brightness):
    global lastBrightness

    if (abs(brightness - lastBrightness) < 5):
        # if analog setting drifs a little, don't bother changing the brightness
        return
    lastBrightness = brightness
    
    if brightness > 255:
        brightness = 255
    elif brightness < 0:
        brightness = 0
        
    # for Sparkfun Serial backpack, brightness range is 128 to 157
    if DISPLAY_TYPE == 'SPARKFUN':
        brightness = 128 + (brightness*29)/ 255        
    if Debug:
        print("setting brightness to " + str(brightness))
    if DISPLAY_TYPE == 'SPARKFUN':  
        cmd = array.array('B', (124, brightness))
    else:
        cmd = array.array('B', (128, brightness))
    writeToDisplay(cmd.tostring())
 

def clearScreen():
    cmd = array.array('B', (COMMAND_PREFIX, 1))
    writeToDisplay(cmd.tostring())


logging.basicConfig(level=logging.ERROR,
                    format='%(asctime)s %(levelname)s %(message)s',
                    filename='serdisplay.log')
log = logging.getLogger()        

initializeDisplay(LCD_NUM_ROWS, LCD_NUM_COLS)
setCursorPos(1, 1, True)                
writeToDisplay("hello ...")
setCursorPos(2, 1, True)                
writeToDisplay("Marah!")

# Note - cannot start > 2 threads if parameters are passed?
# Thread(target=updateDisplay).start()
# Thread(target=readTemperature).start()
# Thread(target=readBrightness).start()

