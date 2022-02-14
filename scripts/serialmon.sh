#!/usr/bin/env bash
#
# Serial Monitor script for Arduino Mega2560
#

BAUD="115200"
TTY="/dev/ArduinoMega2560"

# wait for the mega2560 serial device to appear
while [[ ! -e $TTY ]]; do
  echo "Waiting for $TTY ..."
  sleep 2.0s
done

screen $TTY $BAUD

