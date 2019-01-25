#!/bin/bash
# ---------------------------------------------------------------
# v1.0b
# Written by Vasiliy Sychev (zero.dn.ua [at] gmail.com)
# ---------------------------------------------------------------
# Changelog:
#
# v1.0b (2019.01.25)
# - Fixed result string when ERROR == 0 (removed {} brackets from output)
#
# v1.0a (2019.01.17)
# - Added color for results
# - ps now called only if ROOT_PREFIX is not specified
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

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
NO_COLOR="\033[0m"

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
    echo -e "${GREEN}OK${NO_COLOR}"
else
    echo -e "${RED}NOT FOUND${NO_COLOR}"
    ERROR=1
fi

# ---------------------------------------------------------------

echo -n "Checking for libftd2xx.so................."

if [ -e ${ROOT_PREFIX}/${LIB_FTD2XX} ]; then
    echo -e "${GREEN}OK${NO_COLOR}"
else
    echo -e "${RED}NOT FOUND${NO_COLOR}"
    ERROR=1
fi

# ---------------------------------------------------------------

echo -n "Checking for tty0tty in /etc/modules......"
grep tty0tty /etc/modules > /dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}OK${NO_COLOR}"
else
    echo -e "${RED}NOT ENABLED${NO_COLOR}"
    ERROR=1
fi

# ---------------------------------------------------------------

echo -n "Checking for tty0tty module in kernel....."

if [ "$ROOT_PREFIX" = "" ]; then
    lsmod | grep tty0tty > /dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}OK${NO_COLOR}"
    else
        echo -e "${RED}NOT LOADED${NO_COLOR}"
        ERROR=1
    fi
else
    echo -e "${YELLOW}SKIPPED${NO_COLOR}"
fi

# ---------------------------------------------------------------

echo -n "Checking for port definition in INI file.."

grep $PORT_STR ${ROOT_PREFIX}/${INI_PATH}/mon650.ini.template > /dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}OK${NO_COLOR}"
else
    echo -e "${RED}NOT FOUND${NO_COLOR}"
    ERROR=1
fi

# ---------------------------------------------------------------

echo -n "Checking for elmiko_simulator binary......"

if [ -e ${ROOT_PREFIX}/${APP_PATH}/elmiko_simulator ]; then
    echo -n -e "${GREEN}OK${NO_COLOR}\nChecking elmiko_simulator checksum........"
    MD5SUM_OUTPUT=$(md5sum ${ROOT_PREFIX}/${APP_PATH}/elmiko_simulator)

    if [ $? -eq 0 ]; then
        MD5SUM=$(echo $MD5SUM_OUTPUT | cut --delimiter=" " --fields=1)
        
        if [ ${MD5SUM} = ${CORRECT_MD5} ]; then
            echo -e "${GREEN}OK${NO_COLOR}"
        else
            echo -e "${RED}MISMATCH${NO_COLOR}"
            ERROR=1
        fi
    else
        echo -e "${RED}ERROR RUNNING MD5SUM${NO_COLOR}"
        ERROR=1
    fi
else
    echo -e "${RED}NOT FOUND${NO_COLOR}"
    ERROR=1
fi

# ---------------------------------------------------------------

echo -n "Checking if start_elmiko.sh is running...."

if [ "$ROOT_PREFIX" = "" ]; then
    ps -f -U $USER_NAME > $TMP_FILE
    grep start_elmiko.sh $TMP_FILE > /dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}OK${NO_COLOR}"
    else
        echo -e "${RED}NOT RUNNING${NO_COLOR}"
        ERROR=1
    fi
else
    echo -e "${YELLOW}SKIPPED${NO_COLOR}"
fi

# ---------------------------------------------------------------

echo -n "Checking if elmiko_simulator is running..."

if [ "$ROOT_PREFIX" = "" ]; then
    ps -f -U $USER_NAME > $TMP_FILE
    grep elmiko_simulator $TMP_FILE > /dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}OK${NO_COLOR}"
    else
        echo -e "${RED}NOT RUNNING${NO_COLOR}"
        ERROR=1
    fi
else
    echo -e "${YELLOW}SKIPPED${NO_COLOR}"
fi

# ---------------------------------------------------------------

if [ $ERROR -eq 0 ]; then
    echo -e "\nResult: ${GREEN}no problems detected${NO_COLOR}"
    exit 0
fi

echo -e "\nResult: ${RED}problems was detected. aEEG may not work on this device!${NO_COLOR}"
exit 1
