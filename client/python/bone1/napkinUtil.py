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

import urllib2, base64
import re

#
# Napkin config
DEVICE_ID="bone1"
NAPKIN_URLS=["http://192.168.2.78:4567", "http://192.168.2.35:4567", "http://192.168.2.236:4567"]
NAPKIN_URL_INDEX = 1

def getConfigUrl(napkinUrl):
	return napkinUrl + "/config"

def getConfigDeviceUrl(napkinUrl):
	return napkinUrl + "/config/" + DEVICE_ID

def getChatterUrl(napkinUrl):
	return napkinUrl + "/chatter"

#
# Napkin util

def getConfigValue(key):
    napkinConfigUrl=getConfigDeviceUrl(NAPKIN_URLS[NAPKIN_URL_INDEX]) + "?key=" + key
    configValue="??? error ???"
    try:
        request = urllib2.Request(napkinConfigUrl);
        authHeader = base64.encodestring('%s:%s' % (DEVICE_ID, DEVICE_ID)).replace('\n', '')
        request.add_header("Authorization", "Basic %s" % authHeader)
        configValue = urllib2.urlopen(request).read()
    except urllib2.URLError as urlError:
        print "URL Error in getConfigValue: {0}".format(urlError.strerror)
    except urllib2.HTTPError as httpError:
        print "HTTP Error in getConfigValue: {0}".format(httpError.strerror)
    #
    return configValue

def putConfigValue(key, value):
    napkinConfigUrl=getConfigDeviceUrl(NAPKIN_URLS[NAPKIN_URL_INDEX]) + "?key=" + key
    configValue="??? error ???"
    try:
	opener = urllib2.build_opener(urllib2.HTTPHandler)
        request = urllib2.Request(napkinConfigUrl, value);
        authHeader = base64.encodestring('%s:%s' % (DEVICE_ID, DEVICE_ID)).replace('\n', '')
        request.add_header("Authorization", "Basic %s" % authHeader)
        request.add_header("Content-Type", "text/plain")
	request.get_method = lambda: 'PUT'
        configValue = opener.open(request).read()
    except urllib2.URLError as urlError:
        print "URL Error in putConfigValue: {0}".format(urlError.strerror)
    except urllib2.HTTPError as httpError:
        print "HTTP Error in putConfigValue: {0}".format(httpError.strerror)
    #
    return configValue

def postDeviceConfig():
    postDeviceConfigUrl=getConfigUrl(NAPKIN_URLS[NAPKIN_URL_INDEX]) + "?sub=" + DEVICE_ID
    try:
        request = urllib2.Request(postDeviceConfigUrl, "")
        authHeader = base64.encodestring('%s:%s' % (DEVICE_ID, DEVICE_ID)).replace('\n', '')
        request.add_header("Authorization", "Basic %s" % authHeader)
        request.add_header("Content-Type", "text/plain")
        response = urllib2.urlopen(request)
        responseText = response.read()
    except urllib2.URLError as urlError:
        print "URL Error in postConfigNode: {0}".format(urlError.strerror)
    except urllib2.HTTPError as httpError:
        print "HTTP Error in postConfigNode: {0}".format(httpError.strerror)
    #
    return responseText

def getOrInitConfigValue(key, defaultValue):
    currentValue = getConfigValue(key)
    if (not currentValue):
        putConfigValue(key, defaultValue)
	currentValue = defaultValue
    return currentValue

def composeChatterText(cycle, startCount):
    chatterText = ""
    chatterText += "vitals.id=" + DEVICE_ID + "\n"
    chatterText += "vitals.startCount~i=" + str(startCount) + "\n"
    chatterText += "vitals.currentCycle~i=" + str(cycle) + "\n"
    return chatterText

def postChatter(chatterText):
    napkinChatterUrl=getChatterUrl(NAPKIN_URLS[NAPKIN_URL_INDEX]) + "?format=napkin_kv"
    responseText="??? error ???"
    try:
        request = urllib2.Request(napkinChatterUrl, chatterText)
        authHeader = base64.encodestring('%s:%s' % (DEVICE_ID, DEVICE_ID)).replace('\n', '')
        request.add_header("Authorization", "Basic %s" % authHeader)
        request.add_header("Content-Type", "text/plain")
        response = urllib2.urlopen(request)
        responseText = response.read()
    except urllib2.URLError as urlError:
        print "URL Error in postChatter: {0}".format(urlError.strerror)
    except urllib2.HTTPError as httpError:
        print "HTTP Error in postChatter: {0}".format(httpError.strerror)
    #
    return responseText


