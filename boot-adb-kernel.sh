#!/bin/sh
# Upload & boot kernel/ramdisk when U-Boot is in 'USB Burning' mode

# only works on x86_64 Linux
if [ "$(uname -s)" != "Linux" ] || [ "$(uname -m)" != "x86_64" ]; then
    echo "The amlogic-usb-tool binary is only compatible with x86_64 Linux"
    echo "  This system is: $(uname -s) $(uname -m)"
    exit 1
fi

# need to be root
if [ "$(id -u)" != "0" ]; then
    echo "Must be run as root"
    exit 1
fi


DIR=$(dirname $(realpath $0))
UPDTOOL=$DIR/amlogic-usb-tool

# these files make up all the info about what we are booting
KERNEL=$DIR/images/superbird-adb.kernel.img
INITRD=$DIR/images/superbird-adb.initrd.img
ENV=$DIR/images/env.txt

# addresses to write things in memory
KERNEL_ADDR=0x01080000
INITRD_ADDR=0x13000000
ENV_ADDR=0x13000000


echo "sending env"

# setup env, aka boot arguments
$UPDTOOL bulkcmd "amlmmc env"

# newlines in env.txt make it easier to edit, but must be removed before we write it to the device
TEMP_ENV="/tmp/$(uuidgen).txt"
tr -d '\n' < "$ENV" > "$TEMP_ENV"

ENV_SIZE=$(printf "0x%x" "$(stat -c %s "$TEMP_ENV")")
$UPDTOOL write "$TEMP_ENV" $ENV_ADDR
$UPDTOOL bulkcmd "env import -t $ENV_ADDR $ENV_SIZE"

echo "sending kernel and initrd"

# write the kernl and initrd into memory
$UPDTOOL write "$KERNEL" $KERNEL_ADDR
$UPDTOOL write "$INITRD" $INITRD_ADDR

echo 'Booting kernel...'
$UPDTOOL bulkcmd "booti $KERNEL_ADDR $INITRD_ADDR"

echo "Ignore the above error, it still worked"
