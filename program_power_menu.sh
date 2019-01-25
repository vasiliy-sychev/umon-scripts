#!/bin/bash
# ---------------------------------------------------------------
# v1.0
# Written by Vasiliy Sychev (zero.dn.ua [at] gmail.com)
# ---------------------------------------------------------------
# Changelog:
#
# v1.0 (2019.01.25)
# - Initial release
#

TMP_FILE="/tmp/program_pwr_menu_value"
MODULES_DIR="mon700-scripts-master/home/debian/fw_mon700_tools/modules"

# ---------------------------------------------------------------

if [ "$1" = "" ]; then
    echo "Error: required parameter (service menu base dir path) not specified"
    exit 1
fi

BASE_DIR=$1

# ---------------------------------------------------------------

CURRENT_ITEM=1
EXIT_FLAG=0

while [ $EXIT_FLAG -eq 0 ]; do

    dialog --clear --title "Program power management unit" --default-item $CURRENT_ITEM --menu "Please select version from list:" 0 0 0 \
    1 "Exit this menu (return to main)" \
    2 "HV70 SV62" \
    3 "HV78 SV84" 2> $TMP_FILE

    RESULT=$?
    ITEM=$(cat $TMP_FILE)

    clear

    case $RESULT in
        0)
            echo -n "Item $ITEM selected, "
            ;;
        1)
            echo "Cancel pressed, exiting..."
            exit 0
            ;;
        *)
            echo "Internal error or ESC button was pressed, exiting..."
            exit 0
            ;;
    esac

    case $ITEM in
        1)
            echo "exiting menu..."
            exit 0
            ;;
        2)
            echo "updating PMU firmware..."
            cd $BASE_DIR/mon700-scripts-master/home/debian/fw_mon700_tools/pwr_loader
            ./pwr_loader --file=pow700slave_HV70SV62.a43
            cd $BASE_DIR
            CURRENT_ITEM=2
            read -s -n 1 -p "Press any key to continue..."
            ;;
        3)
            echo "updating PMU firmware..."
            cd $BASE_DIR/mon700-scripts-master/home/debian/fw_mon700_tools/pwr_loader
            ./pwr_loader --file=pow700slave_HV78SV84.a43
            cd $BASE_DIR
            CURRENT_ITEM=3
            read -s -n 1 -p "Press any key to continue..."
            ;;
        *)
            echo "restarting menu..."
            ;;
    esac

done

exit 0
