#!/bin/bash
# ---------------------------------------------------------------
# v1.0
# Written by Vasiliy Sychev (zero.dn.ua [at] gmail.com)
# ---------------------------------------------------------------
# Changelog:
#
# v1.0 (2019.01.08)
# - Initial release. Just works.
#

TMP_FILE="/tmp/aeeg_check_tmp"
USER_NAME="debian"
LIB_ELMCFM="usr/lib/libelmcfm.so"
LIB_FTD2XX="usr/lib/libftd2xx.so"
APP_PATH="home/${USER_NAME}/mon650"
INI_PATH="home/${USER_NAME}/scripts"
PORT_STR="/dev/tnt1"

# MD5 hash for current version of elmiko_simulator application
CORRECT_MD5="769bb2685b0784b72101e53bad746574"

# ---------------------------------------------------------------

if [ "$ROOT_PREFIX" = "" ]; then
    if [ "$1" = "" ]; then
        ROOT_PREFIX=""
        echo "No ROOT_PREFIX specified, using default value"
    else
        ROOT_PREFIX=$1
        echo "ROOT_PREFIX=${ROOT_PREFIX}, runtime checks will be skipped"
    fi
else
    echo "ROOT_PREFIX=${ROOT_PREFIX}, runtime checks will be skipped"
fi

# ---------------------------------------------------------------

echo -e "Checking aEEG dependencies...\n"
ERROR=0

# ---------------------------------------------------------------

echo -n "Checking for libelmcfm.so................."

if [ -e ${ROOT_PREFIX}/${LIB_ELMCFM} ]; then
    echo "OK"
else
    echo "NOT FOUND"
    ERROR=1
fi

# ---------------------------------------------------------------

echo -n "Checking for libftd2xx.so................."

if [ -e ${ROOT_PREFIX}/${LIB_FTD2XX} ]; then
    echo "OK"
else
    echo "NOT FOUND"
    ERROR=1
fi

# ---------------------------------------------------------------

echo -n "Checking for tty0tty in /etc/modules......"
grep tty0tty /etc/modules > /dev/null

if [ $? -eq 0 ]; then
    echo "OK"
else
    echo "NOT ENABLED"
    ERROR=1
fi

# ---------------------------------------------------------------

echo -n "Checking for tty0tty module in kernel....."

if [ "$ROOT_PREFIX" = "" ]; then
    lsmod | grep tty0tty > /dev/null

    if [ $? -eq 0 ]; then
        echo "OK"
    else
        echo "NOT LOADED"
        ERROR=1
    fi
else
    echo "SKIPPED"
fi

# ---------------------------------------------------------------

echo -n "Checking for port definition in INI file.."

grep $PORT_STR ${ROOT_PREFIX}/${INI_PATH}/mon650.ini.template > /dev/null

if [ $? -eq 0 ]; then
    echo "OK"
else
    echo "NOT FOUND"
    ERROR=1
fi

# ---------------------------------------------------------------

echo -n "Checking for elmiko_simulator binary......"

if [ -e ${ROOT_PREFIX}/${APP_PATH}/elmiko_simulator ]; then
    echo -n -e "OK\nChecking elmiko_simulator checksum........"
    MD5SUM_OUTPUT=$(md5sum ${ROOT_PREFIX}/${APP_PATH}/elmiko_simulator)

    if [ $? -eq 0 ]; then
        MD5SUM=$(echo $MD5SUM_OUTPUT | cut --delimiter=" " --fields=1)
        
        if [ ${MD5SUM} = ${CORRECT_MD5} ]; then
            echo "OK"
        else
            echo "MISMATCH"
            ERROR=1
        fi
    else
        echo "ERROR RUNNING MD5SUM"
        ERROR=1
    fi
else
    echo "NOT FOUND"
    ERROR=1
fi

# ---------------------------------------------------------------

echo -n "Checking if start_elmiko.sh is running...."
ps -f -U $USER_NAME > $TMP_FILE

if [ "$ROOT_PREFIX" = "" ]; then
    grep start_elmiko.sh $TMP_FILE > /dev/null

    if [ $? -eq 0 ]; then
        echo "OK"
    else
        echo "NOT RUNNING"
        ERROR=1
    fi
else
    echo "SKIPPED"
fi

# ---------------------------------------------------------------

echo -n "Checking if elmiko_simulator is running..."
ps -f -U $USER_NAME > $TMP_FILE

if [ "$ROOT_PREFIX" = "" ]; then
    grep elmiko_simulator $TMP_FILE > /dev/null

    if [ $? -eq 0 ]; then
        echo "OK"
    else
        echo "NOT RUNNING"
        ERROR=1
    fi
else
    echo "SKIPPED"
fi

# ---------------------------------------------------------------

if [ $ERROR -eq 0 ]; then
    echo -e "\nResult: no problems detected"
    exit 0
fi

echo -e "\nResult: problems was detected. aEEG may not work on this device!"
exit 1
