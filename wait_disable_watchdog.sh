#!/bin/bash
# ---------------------------------------------------------------
# v1.0
# Written by Vasiliy Sychev (zero.dn.ua [at] gmail.com)
# ---------------------------------------------------------------
# Changelog:
#
# v1.0 (2018.12.23)
# - Initial release. Just works.
#

BIN_DATA_PATH="mon700-scripts-master/home/debian/scripts/bin-data"
BIN_COMMAND_FILE="mon700_set_app_wdt_disabled.bin"
DEVICE_PORT="/dev/ttyACM0"

# ---------------------------------------------------------------

if [ "$1" = "" ]; then
    echo "Error: required parameter (service menu base dir path) not specified"
    exit 1
fi

BASE_DIR=$1

# ---------------------------------------------------------------

echo -n "Waiting for embedded controller firmware startup..."

LOOP_COUNT=10

while [ $LOOP_COUNT -ne 0 ]; do
    echo -n "${LOOP_COUNT}..."
    sleep 1
    LOOP_COUNT=$((LOOP_COUNT-1))
done

echo " "
echo "Disabling watchdog..."

cat $BASE_DIR/$BIN_DATA_PATH/$BIN_COMMAND_FILE > $DEVICE_PORT

exit 0
