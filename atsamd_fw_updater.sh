#!/bin/bash
# ---------------------------------------------------------------
# v1.0a
# Written by Vasiliy Sychev (zero.dn.ua [at] gmail.com)
# ---------------------------------------------------------------
# Changelog:
#
# v1.0a (2019.02.01)
# - Added color output
#
# v1.0 (2018.12.21)
# - Initial release. Just works.
#

ATSAMD_FW_DIR="mon700-scripts-master/home/debian/fw_mon700_tools/atsam_loader"
FW_FILE_NAME="mon71xio.bin"
DEV_NAME="/dev/sda"
MOUNT_POINT="/media/debian/bootloader"

# ---------------------------------------------------------------

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
NO_COLOR="\033[0m"

# ---------------------------------------------------------------

echo -e "*** ${GREEN}MON700 embedded controller firmware updater script${NO_COLOR} ***"
echo "-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -"

if [ "$1" = "" ]; then
    echo -e "${RED}Error: required parameter (service menu base dir path) not specified${NO_COLOR}"
    exit 1
fi

BASE_DIR=$1

# ---------------------------------------------------------------

echo -n "Checking if device is already mounted... "
mount | grep $DEV_NAME > /dev/null

if [ $? -eq 0 ]; then
    echo -e "${YELLOW}MOUNTED${NO_COLOR}, unmounting..."
    umount $DEV_NAME

    if [ $? -ne 0 ]; then
        echo -e "${RED}Error unmounting device!${NO_COLOR}"
        exit 1
    fi
else
    echo -e "${GREEN}not mounted${NO_COLOR}"
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
    echo -e "${RED}Error: timeout exceeded${NO_COLOR}"
    exit 1
fi

# ---------------------------------------------------------------

echo -n "Checking if device is auto-mounted... "
sleep 3

mount | grep $DEV_NAME > /dev/null

if [ $? -eq 0 ]; then
    echo -e "${YELLOW}MOUNTED${NO_COLOR}, unmounting..."
    umount $DEV_NAME

    if [ $? -ne 0 ]; then
        echo -e "${RED}Error unmounting device!${NO_COLOR}"
        exit 1
    fi
else
    echo -e "${GREEN}not mounted${NO_COLOR}"
fi

# ---------------------------------------------------------------

echo "Checking filesystem on device..."
fsck.fat -n $DEV_NAME

if [ $? -ne 0 ]; then
    echo -e "${RED}Errors was found on filesystem${NO_COLOR}"
    exit 1
fi

# ---------------------------------------------------------------

echo "Mounting filesystem..."
mount $DEV_NAME $MOUNT_POINT

if [ $? -ne 0 ]; then
    echo -e "${RED}Error mounting filesystem${NO_COLOR}"
    exit 1
fi

# ---------------------------------------------------------------

echo "Copying file..."
cp -v $BASE_DIR/$ATSAMD_FW_DIR/$FW_FILE_NAME $MOUNT_POINT

if [ $? -ne 0 ]; then
    echo -e "${RED}Error copying file${NO_COLOR}"
    exit 1
fi

# ---------------------------------------------------------------

echo "Syncing disks..."
sync

echo "Unmounting filesystem..."
umount $DEV_NAME

if [ $? -ne 0 ]; then
    echo -e "${RED}Error unmounting filesystem${NO_COLOR}"
    exit 1
fi

# ---------------------------------------------------------------

echo 0 > /dev/poweroff-gpio

echo -e "${GREEN}Firmware was successfully written to device!${NO_COLOR}"
exit 0
