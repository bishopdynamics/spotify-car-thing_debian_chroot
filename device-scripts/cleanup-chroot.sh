#!/bin/sh

# need to be root
if [ "$(id -u)" != "0" ]; then
    echo "Must be run as root"
    exit 1
fi

ROOT=/debian-root

unmount_point() {
    # unmount given mountpoint within the chroot folder
    MOUNT_POINT="$1"
    mountpoint "${ROOT}/${MOUNT_POINT}" 2>/dev/null && umount "${ROOT}/${MOUNT_POINT}"
}

echo "Cleaning up chroot mounts"
unmount_point "proc"
unmount_point "sys"
unmount_point "dev/pts"
unmount_point "dev"
unmount_point "tmp"
unmount_point "run/dbus"
unmount_point "run"
unmount_point "var"

mountpoint $ROOT 2>/dev/null && umount $ROOT

echo "Cleanup complete"