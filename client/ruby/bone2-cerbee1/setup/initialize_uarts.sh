#/bin/bash

cd /lib/firmware
echo ttyO1_armhf.com > /sys/devices/bone_capemgr.8/slots
echo ttyO2_armhf.com > /sys/devices/bone_capemgr.8/slots

