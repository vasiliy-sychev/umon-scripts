#!/bin/bash
# ---------------------------------------------------------------
# v1.1
# Written by Vasiliy Sychev (zero.dn.ua [at] gmail.com)
# ---------------------------------------------------------------
# Changelog:
#
# v1.1 (2018.12.22)
# - Added menu items for ECG12, ICG, AAGPO2HX 
# - Added variable CURRENT_ITEM. The dialog state (selected item) now will be restored after programming module(s)
#
# v1.0 (2018.12.18)
# - Initial release, available modules: HUB2, UPRN, UPRN m0, IBP2, CO, BIS
#

TMP_FILE="/tmp/ext_mod_menu_value"
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

    dialog --clear --title "Program external modules" --default-item $CURRENT_ITEM --menu "Please select module from list:" 0 0 0 \
    1 "Exit this menu (return to main)" \
    2 "HUB2 (uniport hub)" \
    3 "UPRN (printer)" \
    4 "UPRN m0 (printer)" \
    5 "IBP2 (invasive blood pressure)" \
    6 "C.O. (cardiac output)" \
    7 "BIS" \
    8 "ECG12" \
    9 "ICG" \
    10 "AAGPO2HX" 2> $TMP_FILE

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
            echo "updating hub firmware..."
            cd $BASE_DIR/$MODULES_DIR
            ./update_hub2.sh
            read -s -n 1 -p "Press any key..."
            cd $BASE_DIR
            CURRENT_ITEM=2
            ;;
        3)
            echo "updating printer (UPRN) firmware..."
            cd $BASE_DIR/$MODULES_DIR
            ./update_uprn.sh
            read -s -n 1 -p "Press any key..."
            cd $BASE_DIR
            CURRENT_ITEM=3
            ;;
        4)
            echo "updating printer (UPRN m0) firmware..."
            cd $BASE_DIR/$MODULES_DIR
            ./update_uprn_m0.sh
            read -s -n 1 -p "Press any key..."
            cd $BASE_DIR
            CURRENT_ITEM=4
            ;;
        5)
            echo "updating IBP module firmware..."
            cd $BASE_DIR/$MODULES_DIR
            ./update_ibp2.sh
            read -s -n 1 -p "Press any key..."
            cd $BASE_DIR
            CURRENT_ITEM=5
            ;;
        6)
            echo "updating C.O. module firmware..."
            cd $BASE_DIR/$MODULES_DIR
            ./update_hub2.sh
            read -s -n 1 -p "Press any key..."
            cd $BASE_DIR
            CURRENT_ITEM=6
            ;;
        7)
            echo "updating BIS module firmware..."
            cd $BASE_DIR/$MODULES_DIR
            ./update_bis.sh
            read -s -n 1 -p "Press any key..."
            cd $BASE_DIR
            CURRENT_ITEM=7
            ;;
        8)
            echo "updating ECG12 module firmware..."
            cd $BASE_DIR/$MODULES_DIR
            ./update_ecg12.sh
            read -s -n 1 -p "Press any key..."
            cd $BASE_DIR
            CURRENT_ITEM=8
            ;;
        9)
            echo "updating ICG module firmware..."
            cd $BASE_DIR/$MODULES_DIR
            ./update_icg.sh
            read -s -n 1 -p "Press any key..."
            cd $BASE_DIR
            CURRENT_ITEM=9
            ;;
        10)
            echo "updating AAGPO2HX module firmware..."
            cd $BASE_DIR/$MODULES_DIR
            ./update_aagpo2hx.sh
            read -s -n 1 -p "Press any key..."
            cd $BASE_DIR
            CURRENT_ITEM=10
            ;;
        *)
            echo "restarting menu..."
            ;;
    esac

done

exit 0
