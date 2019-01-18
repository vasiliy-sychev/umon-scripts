#!/bin/bash
# ---------------------------------------------------------------
# v1.1
# Written by Vasiliy Sychev (zero.dn.ua [at] gmail.com)
# ---------------------------------------------------------------
# Changelog:
#
# v1.1 (2018.12.22)
# - Added variable CURRENT_ITEM. The dialog state (selected item) now will be restored after programming module(s)
#
# v1.0 (2018.12.21)
# - Initial release. Just works.
#

TMP_FILE="/tmp/int_mod_menu_value"
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

    dialog --clear --title "Program internal modules" --default-item $CURRENT_ITEM --menu "Please select module from list:" 0 0 0 \
    1 "Exit this menu (return to main)" \
    2 "Auto-programming (SOT/HUB->ECG->NIBP)" \
    3 "Auto-programming (SMT/HUB->ECG->NIBP)" \
    4 "SOT/HUB (Nellcor)" \
    5 "SMT/HUB (Masimo)" \
    6 "ECG" \
    7 "NIBP" 2> $TMP_FILE

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
            echo "updating all internal modules (SOT, ECG, NIBP)..."
            cd $BASE_DIR/$MODULES_DIR
            ./update_sot.sh
            ./update_ecg2.sh
            ./update_nibp.sh
            read -s -n 1 -p "Press any key..."
            cd $BASE_DIR
            CURRENT_ITEM=2
            ;;
        3)
            echo "updating all internal modules (SMT, ECG, NIBP)..."
            cd $BASE_DIR/$MODULES_DIR
            ./update_smt.sh
            ./update_ecg2.sh
            ./update_nibp.sh
            read -s -n 1 -p "Press any key..."
            cd $BASE_DIR
            CURRENT_ITEM=3
            ;;
        4)
            echo "updating SOT module firmware..."
            cd $BASE_DIR/$MODULES_DIR
            ./update_sot.sh
            read -s -n 1 -p "Press any key..."
            cd $BASE_DIR
            CURRENT_ITEM=4
            ;;
        5)
            echo "updating SMT module firmware..."
            cd $BASE_DIR/$MODULES_DIR
            ./update_smt.sh
            read -s -n 1 -p "Press any key..."
            cd $BASE_DIR
            CURRENT_ITEM=5
            ;;
        6)
            echo "updating ECG module firmware..."
            cd $BASE_DIR/$MODULES_DIR
            ./update_ecg2.sh
            read -s -n 1 -p "Press any key..."
            cd $BASE_DIR
            CURRENT_ITEM=6
            ;;
        7)
            echo "updating NIBP module firmware..."
            cd $BASE_DIR/$MODULES_DIR
            ./update_nibp.sh
            read -s -n 1 -p "Press any key..."
            cd $BASE_DIR
            CURRENT_ITEM=7
            ;;
        *)
            echo "restarting menu..."
            ;;
    esac

done

exit 0
