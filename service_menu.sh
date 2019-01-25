#!/bin/bash
# ---------------------------------------------------------------
# Advanced version of original test-menu.sh
# Written by Vasiliy Sychev (zero.dn.ua [at] gmail.com)
# ---------------------------------------------------------------
# Changelog:
#
# v1.0 (2019.01.25)
# - Initial release. Just works.
#

ASKPASS_FILE="/tmp/askpass.sh"
TMP_FILE="/tmp/service_menu_value"

EMMC_DEV_NAME="mmcblk0"
SERVICE_MENU_BASE_DIR="/home/debian/mon71x"

# ---------------------------------------------------------------

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
NO_COLOR="\033[0m"

# ---------------------------------------------------------------

function init_askpass {
    rm -f $ASKPASS_FILE 2> /dev/null
    echo "#!/bin/sh" > $ASKPASS_FILE
    echo "echo Boundary" >> $ASKPASS_FILE
    chmod a+x $ASKPASS_FILE
    export SUDO_ASKPASS=$ASKPASS_FILE
}

function remove_askpass {
    rm -f $ASKPASS_FILE
    export SUDO_ASKPASS=""
}

# ---------------------------------------------------------------

CURRENT_ITEM=1
EXIT_FLAG=0

while [ $EXIT_FLAG -eq 0 ]; do

    dialog --clear --title "UTAS UM300 MON71x Service Menu" --default-item $CURRENT_ITEM --menu "Please select operation from list:" 22 60 14 \
    1 "Create filesystem on eMMC" \
    2 "Check board" \
    3 "Program ATSAMD21J18 (embedded controller)" \
    4 "Program power (PMU)" \
    5 "Program internal modules (SOT/SMT, ECG, NIBP)" \
    6 "Program external modules (IBP, C.O., BIS, ...)" \
    7 "Calibrate touchscreen" \
    8 "Program UniPort FTDI EEPROM" \
    9 "Program Printer FTDI EEPROM" \
    10 "Copy MON71x application" \
    11 "TFT test" \
    12 "Power off / Shut down" \
    13 "Terminal" \
    14 "Exit this menu (dangerous!)" 2> $TMP_FILE

    RESULT=$?
    ITEM=$(cat $TMP_FILE)

    clear

    case $RESULT in
        0)
            echo "Item $ITEM selected"
            ;;

        1)
            echo -e "${YELLOW}Cancel pressed${NO_COLOR}"
            sleep 1
            continue
            ;;

        *)
            echo -e "${YELLOW}Internal error or ESC button was pressed${NO_COLOR}"
            sleep 1
            continue
            ;;
    esac

    case $ITEM in
        1) # Create filesystem on eMMC
            CURRENT_ITEM=1
            dialog --clear --defaultno --title "Create filesystem on eMMC" --yesno "Are you sure?" 0 0
        
            if [ $? -eq 0 ]; then
                clear
                ./create_mon71x_mmcblk0.sh
                ./copy-app-mon715-files.sh
                sync
                read -s -n 1 -p "Press any key to continue..."
            fi
            ;;

        2) # Check board
            CURRENT_ITEM=2
            ./check-board.sh
            read -s -n 1 -p "Press any key to continue..."
            ;;

        3) # Program ATSAMD
            CURRENT_ITEM=3
            dialog --clear --defaultno --title "Program embedded controller" --yesno "Are you sure?" 0 0

            if [ $? -eq 0 ]; then
                clear
                init_askpass
                echo "Starting atsamd_fw_updater.sh with superuser rights..."
                sudo -A ./atsamd_fw_updater.sh $SERVICE_MENU_BASE_DIR
                sudo -A ./wait_disable_watchdog.sh $SERVICE_MENU_BASE_DIR
                remove_askpass
                read -s -n 1 -p "Press any key to continue..."
            fi
            ;;

        4) # Program power
            CURRENT_ITEM=4
            ./program_power_menu.sh $SERVICE_MENU_BASE_DIR
            ;;

        5) # Program internal modules
            CURRENT_ITEM=5
            ./internal_modules_menu.sh $SERVICE_MENU_BASE_DIR
            ;;

        6) # Program external modules
            CURRENT_ITEM=6
            ./external_modules_menu.sh $SERVICE_MENU_BASE_DIR
            ;;

        7) # Calibrate touchscreen
            CURRENT_ITEM=7
            cd $SERVICE_MENU_BASE_DIR/mon700-scripts-master/home/debian/fw_mon700_tools/calib_ts/
            FB_NUM=1
            if [ -e /dev/fb3 ]; then
                FB_NUM=2
            fi
            ./calib_ts --port=/dev/ttyACM0 --frame_buffer=/dev/fb${FB_NUM} > /dev/null
            ;;

        8) # Program UniPort FTDI EEPROM
            CURRENT_ITEM=8
            cd $SERVICE_MENU_BASE_DIR/ftdi
            ./set-uniports-eeprom.sh
            cd $SERVICE_MENU_BASE_DIR
            read -s -n 1 -p "Press any key to continue..."
            ;;

        9) # Program Printer FTDI EEPROM
            CURRENT_ITEM=9
            cd $SERVICE_MENU_BASE_DIR/ftdi
            ./set-uniprn-eeprom.sh
            cd $SERVICE_MENU_BASE_DIR
            read -s -n 1 -p "Press any key to continue..."
            ;;

        10) # Copy applcation
            CURRENT_ITEM=10
            ./copy-app-mon715-files.sh
            read -s -n 1 -p "Press any key to continue..."
            ;;
        
        11) # TFT test
            CURRENT_ITEM=11
            cd $SERVICE_MENU_BASE_DIR/mon700-scripts-master/home/debian/fw_mon700_tools/lcd_test
            FB_NUM=1
            if [ -e /dev/fb3 ]; then
                FB_NUM=2
            fi
            ./lcd_test --frame_buffer=/dev/fb${FB_NUM} > /dev/null
            cd $SERVICE_MENU_BASE_DIR
            ;;

        12) # Power off
            echo "Shutting down machine..."
            sudo shutdown -P now > /dev/null
            sleep 1
            EXIT_FLAG=1
            ;;
        
        13) # Terminal
            CURRENT_ITEM=13
            xfce4-terminal --maximize
            ;;

        14) # Exit menu
            CURRENT_ITEM=14
            dialog --clear --defaultno --title "Leave service menu" --yesno "Are you sure?" 0 0

            if [ $? -eq 0 ]; then
                clear
                echo -e "${GREEN}Exiting service menu...${NO_COLOR}"
                EXIT_FLAG=1
                sleep 1
            fi
            ;;

        *)
            echo -e "${RED}Unknown item \"${ITEM}\", restarting menu...${NO_COLOR}"
            sleep 1
            ;;
esac

done

exit 0
