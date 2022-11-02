#!/usr/bin/env bash

# local image file, where we built our new root filesystem
IMAGE_FILE="debian-filesystem.img"

# only works on Linux
if [ "$(uname -s)" != "Linux" ]; then
    echo "This script is only compatible with Linux"
    echo "  This system is: $(uname -s) $(uname -m)"
    exit 1
fi

command -v adb || {
    echo "Error: missing adb, try: apt-get install android-sdk-platform-tools"
    exit 1
}

set -e  # bail on any errors

# set device root filesystem to read/write mode
adb shell mount -o remount,rw /

# first deploy updated scripts
echo "Updating scripts on device"
adb shell "mkdir -p /scripts"
adb push device-scripts/cleanup-chroot.sh /scripts/
adb push device-scripts/activate-chroot.sh /scripts/

if [ "$1" == "-s" ]; then
    # only updating scripts
    adb shell ro  # set root filesystem back to read-only
    exit 0
fi

adb shell "/scripts/cleanup-chroot.sh"
adb shell "rm -f /var/${IMAGE_FILE}"
adb push "$IMAGE_FILE" /var/

# set device root filesystem back to read-only
adb shell mount -o remount,ro /

echo "Filesystem status:"
adb shell df -h

echo "Deploy complete"
