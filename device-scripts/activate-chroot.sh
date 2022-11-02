#!/bin/sh

# prepare and activate chroot

# need to be root
if [ "$(id -u)" != "0" ]; then
    echo "Must be run as root"
    exit 1
fi

if [ ! -f "/scripts/cleanup-chroot.sh" ]; then
    echo "missing cleanup script: /scripts/cleanup-chroot.sh"
    echo "unwilling to continue if we cant clean up after!"
    exit 1
fi

# on the device, where is the debian root
ROOT=/debian-root

copy_from_local() {
    # copy a given local file into the chroot, unless it already exists
    FILE_NAME="$1"
    if [ ! -f "${ROOT}/${FILE_NAME}" ]; then
        echo "copying host version of ${FILE_NAME}"
        cp /etc/passwd "${ROOT}/${FILE_NAME}" || {
            echo "failed to copy local file into chroot: $FILE_NAME"
            exit 1
        }
    fi
}

make_mountpoint() {
    # create a folder within the root, with the given name, to be used as a mountpoint
    MOUNT_POINT="$1"
    if [ ! -d "${ROOT}/${MOUNT_POINT}" ]; then
        echo "making folder for mountpoint: ${ROOT}/$MOUNT_POINT"
        mkdir "${ROOT}/${MOUNT_POINT}" || {
            echo "Failed to mkdir ${ROOT}/${MOUNT_POINT}"
            exit 1
        }
    # else
    #     echo "mountpoint folder already present: $MOUNT_POINT"
    fi
}

mount_bind() {
    # bind mount the given mountpoint within the chroot folder
    MOUNT_POINT="$1"
    make_mountpoint "$MOUNT_POINT"
    echo "mounting ${ROOT}/$MOUNT_POINT"
    mount -o bind "/${MOUNT_POINT}" "${ROOT}/$MOUNT_POINT"
}

mount_tmp() {
    # createa a tmpfs mount within the chroot folder
    MOUNT_POINT="$1"
    make_mountpoint "$MOUNT_POINT"
    echo "creating tmpfs mount: ${ROOT}/${MOUNT_POINT}"
    mount -t tmpfs tmpfs "${ROOT}/${MOUNT_POINT}"
}

echo "mounting / as readwrite"
mount -o remount,rw /
mkdir -p /debian-root
mount /var/debian-filesystem.img $ROOT

copy_from_local "/etc/passwd"
copy_from_local "/etc/resolv.conf"


# copy /var/xorg.conf if available
if [ -f "/var/xorg.conf" ]; then
    cp /var/xorg.conf "${ROOT}/etc/X11/xorg.conf"
fi

echo "bind mounting..."

mount_bind "proc"
mount_bind "sys"
mount_bind "dev"
mount_bind "dev/pts"


mount_tmp "tmp"
mount_tmp "run"
mount_tmp "var"

# make dbus work
mkdir -p "${ROOT}/run/dbus"
mount -o bind "/var/run/dbus" "${ROOT}/run/dbus"

# need to create /var/log
mkdir "${ROOT}/var/log"

echo "entering chroot"
chroot /debian-root /bin/bash

echo "cleaning up"
/scripts/cleanup-chroot.sh

echo "remounting / as read-only"
mount -o remount,ro /


echo "done"