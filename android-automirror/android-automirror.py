#!/bin/env python

import signal
import sys
import subprocess
import pyudev

if __name__ == '__main__':
  context = pyudev.Context()
  monitor = pyudev.Monitor.from_netlink(context)

  def handler(action, device):
    print(action, device)
    try:
      devlinks = set(device.properties['DEVLINKS'].split())
      if action != 'bind' or '/dev/android_adb' not in devlinks:
        return
    except KeyError:
      return
    print('Opening display')
    subprocess.Popen(['scrcpy', '-f'])

  observer = pyudev.MonitorObserver(monitor, handler)
  observer.start()
  sig = signal.sigwait(set([signal.SIGINT]))
  print('Received {}, exitting.'.format(signal.strsignal(sig)))

