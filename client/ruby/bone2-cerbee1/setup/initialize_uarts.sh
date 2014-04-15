####
# Copyright (c) 2014 Chris J Daly (github user cjdaly)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   cjdaly - initial API and implementation
####

cd /lib/firmware
SLOTS_DIR="/sys/devices/bone_capemgr.*/slots"
echo ttyO1_armhf.com > $SLOTS_DIR
echo ttyO2_armhf.com > $SLOTS_DIR
