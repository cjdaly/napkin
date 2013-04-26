####
# Copyright (c) 2013 Chris J Daly (github user cjdaly)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   cjdaly - initial API and implementation
####

# import urllib, urllib2, base64
# import sys, time, datetime, array
# import serial
# import re

#
# Serial LCD setup
import serLcdUtil
serDisplay1 = serLcdUtil.initializeDisplay(1)
serDisplay2 = serLcdUtil.initializeDisplay(2)


import napkinUtil
#

#
# init
#
status="???"
done=False
cycle=0
configCycle=8
postCycle=256

startCountText = napkinUtil.getOrInitConfigValue('device_start_count', '0')
startCount = int(startCountText)
startCount += 1
startCountText = str(startCount)
napkinUtil.putConfigValue('device_start_count', startCountText)
print "startCount: " + startCountText

#
# main loop
#
while(not done):
    cycle += 1
    #
    if (cycle%configCycle == 0):
        status = napkinUtil.getConfigValue('status')
	# print "Config: status=" + status
    #
    if (cycle%postCycle == 0):
        chatterText = napkinUtil.composeChatterText(cycle, startCount)
        chatterResponse = napkinUtil.postChatter(chatterText)
	# print "Chatter: " + chatterResponse
    #
    serLcdUtil.updateLcds(serDisplay1, serDisplay2, startCount, cycle, status)
    time.sleep(1)

