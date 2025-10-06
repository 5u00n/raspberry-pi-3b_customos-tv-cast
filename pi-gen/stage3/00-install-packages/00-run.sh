#!/bin/bash -e
on_chroot << EOFCHROOT
pip3 install --break-system-packages flask flask-cors requests psutil || pip3 install flask flask-cors requests psutil
EOFCHROOT
