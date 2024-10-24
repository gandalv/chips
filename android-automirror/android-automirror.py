#!/bin/env python

import signal
import sys
import subprocess
import pyudev

def on_signal(sig, frame):
  print('signal', sig, frame)
  sys.exit(0)

context = pyudev.Context()
monitor = pyudev.Monitor.from_netlink(context)

def handler(action, device):
  print(action, device)
  try:
    if action != 'bind' or device.properties['adb_adb'] != 'yes':
      return
  except KeyError:
    return
  subprocess.Popen(['scrcpy', '-f'])

observer = pyudev.MonitorObserver(monitor, handler)
observer.start()
signal.signal(signal.SIGINT, on_signal)
signal.pause()

