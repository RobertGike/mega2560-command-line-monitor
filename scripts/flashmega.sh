#!/usr/bin/env bash
#-------------------------------------------------------------------------------
# Flash an image to the Arduino Mega2560
#
# Copyright (c) 2022 Robert I. Gike
#-------------------------------------------------------------------------------

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <device> <baud> <hexfile>"
  exit 1
fi

AVRDUDE="./avrdude"
BAUD="$2"
HEXFILE="$3"
TTY="$1"

STATUS=`ps -ef | grep "screen\s$1" | grep -v grep | wc -l`

if [[ $STATUS -eq 1 ]]; then
  echo "Device $TTY is busy!"
  exit 1
fi

#echo "$AVRDUDE -C${AVRDUDE}.conf -v -patmega2560 -cwiring -P$TTY -b$BAUD -D -Uflash:w:${HEXFILE}:i"

$AVRDUDE -C${AVRDUDE}.conf -v -patmega2560 -cwiring -P$TTY -b$BAUD -D -Uflash:w:${HEXFILE}:i

