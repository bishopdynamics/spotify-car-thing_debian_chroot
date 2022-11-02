#!/usr/bin/env bash

# need to be root
if [ "$(id -u)" != "0" ]; then
    echo "Must be run as root"
    exit 1
fi

# only works on  Linux
if [ "$(uname -s)" != "Linux" ]; then
    echo "This script is only compatible with Linux"
    echo "  This system is: $(uname -s) $(uname -m)"
    exit 1
fi

command -v multistrap || {
    echo "Error: missing multistrap, try: apt-get install multistrap"
    exit 1
}

set -e  # bail on any errors

ARCH="arm64"  # armhf / arm64

# locally, where we built our new root filesystem
LOCAL_ROOT="root"
LOCAL_FILE="debian-filesystem.img"

mountpoint "$LOCAL_ROOT" && umount "$LOCAL_ROOT"

if [ -f "$LOCAL_FILE" ]; then
    rm "$LOCAL_FILE"
fi

echo "creating $LOCAL_FILE"
# create 1.75GB empty file
dd if=/dev/zero of=$LOCAL_FILE bs=1M count=1792

echo "formatting $LOCAL_FILE"
mkfs.ext4 "$LOCAL_FILE"

mkdir -p "$LOCAL_ROOT"
mount "$LOCAL_FILE" "$LOCAL_ROOT"

echo "Building image for $ARCH in: $LOCAL_ROOT"

multistrap -a $ARCH -d "$LOCAL_ROOT" -f multistrap.conf

# add extra files
cp xorg.conf "${LOCAL_ROOT}/etc/X11/"

LOCAL_SIZE=$(du -sh "$LOCAL_ROOT"|awk '{print $1}')

echo "Local root image size: $LOCAL_SIZE"

umount "$LOCAL_ROOT"

echo "Build complete"
