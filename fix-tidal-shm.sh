#!/bin/bash
set -euo pipefail

# Fix /dev/shm mount options for Chromium/Electron (tidal-hifi)
# Kernel bug with huge=within_size + usrquota → shm_open fails with ESRCH

echo "Remounting /dev/shm without problematic options..."
sudo mount -o remount,size=50%,mode=1777 /dev/shm

# Verify
if mount | grep /dev/shm | grep -q "huge=within_size"; then
  echo "WARNING: huge=within_size still present. Remount didn't take effect."
  echo "Try: sudo mount -t tmpfs -o size=50%,mode=1777 tmpfs /dev/shm"
else
  echo "OK: /dev/shm remounted cleanly"
fi
