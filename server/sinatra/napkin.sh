#!/bin/bash
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

NAPKIN_SYSTEM=$1

case `uname -i` in
  x86*) JRUBY_ARGS="";;
  arm*) JRUBY_ARGS="--server -J-Xms96M -J-Xmx96M";;
esac

echo "Napkin system: $NAPKIN_SYSTEM, using jruby args: $JRUBY_ARGS"

NAPKIN_LOG="napkin.log"
rm -f $NAPKIN_LOG
touch $NAPKIN_LOG

jruby $JRUBY_ARGS napkin.rb config-$NAPKIN_SYSTEM.json 1>> $NAPKIN_LOG 2>&1 &
NAPKIN_PID=$!

echo "Napkin process: $NAPKIN_PID" >> $NAPKIN_LOG
echo "Napkin process: $NAPKIN_PID, writing to $NAPKIN_LOG"
