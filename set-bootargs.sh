#!/bin/bash

# Set the boot args passed to the kernel by the bootloader

# shellcheck disable=SC2016  # ignore single-quoted ${vars} because we want them to expand on far-end

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
UPDTOOL="$DIR/amlogic-usb-tool"

# First we clear initargs
$UPDTOOL bulkcmd 'amlmmc env'
$UPDTOOL bulkcmd 'setenv initargs init=/sbin/pre-init'

# Now we append options
$UPDTOOL bulkcmd 'setenv initargs ${initargs} ramoops.pstore_en=1'
$UPDTOOL bulkcmd 'setenv initargs ${initargs} ramoops.record_size=0x8000'
$UPDTOOL bulkcmd 'setenv initargs ${initargs} ramoops.console_size=0x4000'
$UPDTOOL bulkcmd 'setenv initargs ${initargs} console=ttyS0,115200n8'  # settings for serial console
$UPDTOOL bulkcmd 'setenv initargs ${initargs} no_console_suspend'
$UPDTOOL bulkcmd 'setenv initargs ${initargs} earlycon=aml-uart,0xff803000'  # make sure console is available as early as possible in boot process


# Now setup the root partition, here we have the important stuff abstracted to variables

# Partition Number
#   system_a: 14
#   system_b: 15
#   data: 18

# we are currently using the data partition for our experiments, because it is 2GB, compared to the 512MB system parititions
#   also, this lets us leave the original system (mostly) alone for now

PART_NUM="14"  # partition number
PART_TYPE="ext4"  # filesystem of partition
PART_RO="ro"  # ro | rw, set readonly or readwrite to mount partition

# the onboard mmc is mmcblk0
ROOT_DEVICE="/dev/mmcblk0p${PART_NUM}"

echo "Setting root device: $ROOT_DEVICE [${PART_TYPE}] (${PART_RO})"

$UPDTOOL bulkcmd 'setenv initargs ${initargs} rootfstype='"$PART_TYPE"  # filesystem of root partition
$UPDTOOL bulkcmd 'setenv initargs ${initargs} '"$PART_RO"' root='"$ROOT_DEVICE"  # device R/O status and device path

# finally, save these changes so they persist across reboot
#   otherwise, they will only apply to the current boot session

$UPDTOOL bulkcmd 'env save'
