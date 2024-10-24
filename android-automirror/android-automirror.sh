#!/bin/env bash

DEVICE=$1

if [[ $DEVICE == "" ]]; then
  echo "No device specified."
  exit 1
fi

udevadm monitor -u | while read line
do
  if [[ $line == *" bind "* && $line == *" $DEVICE "* ]]; then
    echo $line
    scrcpy -f
  fi
done
