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
NAPKIN_PID_FILE="napkin.PID"

case "$1" in
  -start)
  if [ -f "$NAPKIN_PID_FILE" ]; then
    NAPKIN_PID=`cat $NAPKIN_PID_FILE`
    echo "Napkin process $NAPKIN_PID already running."
  elif [ -f "$2/config.json" ]; then
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
  
    echo "starting $2"
    NAPKIN_SYSTEM_DIR=$2
    echo "Napkin system dir: $NAPKIN_SYSTEM_DIR, using jruby args: $JRUBY_ARGS"
    
    jruby $JRUBY_ARGS napkin.rb $NAPKIN_SYSTEM_DIR/config.json 1>> $NAPKIN_LOG 2>&1 &
    NAPKIN_PID=$!
    
    echo "Napkin process: $NAPKIN_PID" >> $NAPKIN_LOG
    echo "$NAPKIN_PID" > $NAPKIN_PID_FILE
    echo "Napkin process: $NAPKIN_PID, log: $NAPKIN_LOG"
  else
    echo "Napkin system configuration file not found at $2/config.json"
  fi
  ;;
  -stop)
  if [ -f "$NAPKIN_PID_FILE" ]; then
    NAPKIN_PID=`cat $NAPKIN_PID_FILE`
    rm $NAPKIN_PID_FILE
    echo "Napkin process $NAPKIN_PID now shutting down."
    tail -f napkin.log --pid=$NAPKIN_PID
  else
    echo "Napkin already stopped or stopping."
  fi
  ;;
  -status)
  if [ -f "$NAPKIN_PID_FILE" ]; then
    NAPKIN_PID=`cat $NAPKIN_PID_FILE`
    echo "Napkin process $NAPKIN_PID apparently running."
  else
    echo "Napkin stopped or stopping."
  fi
  ;;
  *)
  echo "Napkin usage:"
  echo "  ./napkin.sh -start system-config-dir"
  echo "  ./napkin.sh -stop"
  echo "  ./napkin.sh -status"
  ;;
esac

