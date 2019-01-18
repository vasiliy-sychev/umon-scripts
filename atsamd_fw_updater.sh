#!/bin/bash
# ---------------------------------------------------------------
# v1.0
# Written by Vasiliy Sychev (zero.dn.ua [at] gmail.com)
# ---------------------------------------------------------------
# Changelog:
#
# v1.0 (2018.12.21)
# - Initial release. Just works.
#

ATSAMD_FW_DIR="mon700-scripts-master/home/debian/fw_mon700_tools/atsam_loader"
FW_FILE_NAME="mon71xio.bin"
DEV_NAME="/dev/sda"
MOUNT_POINT="/media/debian/bootloader"

# ---------------------------------------------------------------

echo "*** MON700 embedded controller firmware updater script ***"
echo "-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -"

if [ "$1" = "" ]; then
    echo "Error: required parameter (service menu base dir path) not specified"
    exit 1
fi

BASE_DIR=$1

# ---------------------------------------------------------------

echo -n "Checking if device is already mounted... "
mount | grep $DEV_NAME > /dev/null

if [ $? -eq 0 ]; then
    echo "MOUNTED, unmounting..."
    umount $DEV_NAME

    if [ $? -ne 0 ]; then
        echo "Error unmounting device!"
        exit 1
    fi
else
    echo "not mounted"
fi

# ---------------------------------------------------------------

echo "Doing some magic with GPIO pin..."
echo "GPIO = 1"
echo 1 > /dev/poweroff-gpio
sleep 0.1
echo "GPIO = 0"
echo 0 > /dev/poweroff-gpio
sleep 0.1
echo "GPIO = 1"
echo 1 > /dev/poweroff-gpio

# ---------------------------------------------------------------

echo -n "Waiting for device ${DEV_NAME}..."

LOOP_COUNT=0
DEVICE_EXISTS=0

while [ $LOOP_COUNT -lt 120 ]; do
    sleep 0.5

    if [ -e $DEV_NAME ]; then
        LOOP_COUNT=120
        DEVICE_EXISTS=1
    else
        echo -n "."
        LOOP_COUNT=$((LOOP_COUNT+1))
    fi
done

echo " "

if [ $DEVICE_EXISTS -eq 0 ]; then
    echo "Error: timeout exceeded"
    exit 1
fi

# ---------------------------------------------------------------

echo -n "Checking if device is auto-mounted... "
sleep 3

mount | grep $DEV_NAME > /dev/null

if [ $? -eq 0 ]; then
    echo "MOUNTED, unmounting..."
    umount $DEV_NAME

    if [ $? -ne 0 ]; then
        echo "Error unmounting device!"
        exit 1
    fi
else
    echo "not mounted"
fi

# ---------------------------------------------------------------

echo "Checking filesystem on device..."
fsck.fat -n $DEV_NAME

if [ $? -ne 0 ]; then
    echo "Errors was found on filesystem"
    exit 1
fi

# ---------------------------------------------------------------

echo "Mounting filesystem..."
mount $DEV_NAME $MOUNT_POINT

if [ $? -ne 0 ]; then
    echo "Error mounting filesystem"
    exit 1
fi

# ---------------------------------------------------------------

echo "Copying file..."
cp -v $BASE_DIR/$ATSAMD_FW_DIR/$FW_FILE_NAME $MOUNT_POINT

if [ $? -ne 0 ]; then
    echo "Error copying file"
    exit 1
fi

# ---------------------------------------------------------------

echo "Syncing disks..."
sync

echo "Unmounting filesystem..."
umount $DEV_NAME

if [ $? -ne 0 ]; then
    echo "Error unmounting filesystem"
    exit 1
fi

# ---------------------------------------------------------------

echo 0 > /dev/poweroff-gpio

echo "Firmware was successfully written to device!"
exit 0
