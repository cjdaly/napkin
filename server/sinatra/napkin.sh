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

TIMESTAMP=`date +%Y%m%d-%H%M%S`

NAPKIN_LOGS_DIR="logs"
mkdir -p $NAPKIN_LOGS_DIR

NAPKIN_LOG="$NAPKIN_LOGS_DIR/napkin-$TIMESTAMP.log"
touch $NAPKIN_LOG

rm -f napkin.log
ln -s $NAPKIN_LOG napkin.log

case `uname -i` in
  x86*) JRUBY_ARGS="";;
  arm*) JRUBY_ARGS="--server -J-Xms96M -J-Xmx96M";;
esac

NAPKIN_SYSTEM_DIR=$1
echo "Napkin system dir: $NAPKIN_SYSTEM_DIR, using jruby args: $JRUBY_ARGS"

jruby $JRUBY_ARGS napkin.rb $NAPKIN_SYSTEM_DIR/config.json 1>> $NAPKIN_LOG 2>&1 &
NAPKIN_PID=$!

echo "Napkin process: $NAPKIN_PID" >> $NAPKIN_LOG
echo "Napkin process: $NAPKIN_PID, writing to $NAPKIN_LOG"
