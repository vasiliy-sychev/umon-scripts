#!/bin/bash
# ---------------------------------------------------------------
# v1.0
# Written by Vasiliy Sychev (zero.dn.ua [at] gmail.com)
# ---------------------------------------------------------------
# Changelog:
#
# v1.0 (2018.12.19)
# - Initial release. Just works.
#

TMP_FILE="/tmp/service_menu_value"

EMMC_DEV_NAME="mmcblk0"
SERVICE_MENU_BASE_DIR="/home/debian/mon71x"

# ---------------------------------------------------------------

function init_askpass {
    rm -f /tmp/askpass.sh 2> /dev/null
    echo "#!/bin/sh" > /tmp/askpass.sh
    echo "echo Boundary" >> /tmp/askpass.sh
    chmod a+x /tmp/askpass.sh
    export SUDO_ASKPASS="/tmp/askpass.sh"
}

function remove_askpass {
    rm -f /tmp/askpass.sh
    export SUDO_ASKPASS=""
}

# ---------------------------------------------------------------

EXIT_FLAG=0

while [ $EXIT_FLAG -eq 0 ]; do

    dialog --clear --title "MON700 Service Menu" --menu "Please select operation from list:" 0 0 0 \
    1 "(disabled item)" \
    2 "Program ATSAMD21J18 (embedded controller)" \
    3 "Program internal modules (SOT/HUB, ECG, NIBP)" \
    4 "Program external modules (IBP, C.O., BIS, ...)" \
    5 "Shut down" \
    6 "Exit this menu (dangerous!)" 2> $TMP_FILE

    RESULT=$?
    ITEM=$(cat $TMP_FILE)

    clear

case $RESULT in
    0)
        echo "Item $ITEM selected"
        ;;
    1)
        echo "Cancel pressed"
        ;;
    *)
        echo "Internal error or ESC button was pressed"
        ;;
esac

case $ITEM in
    1)
        dialog --clear --defaultno --title "Format eMMC, copy OS files and application" --yesno "Are you sure?" 0 0
        
        if [ $? -eq 0 ]; then
            init_askpass
        fi
        ;;
    2)
        dialog --clear --defaultno --title "Program embedded controller" --yesno "Are you sure" 0 0

        if [ $? -eq 0 ]; then
            clear
            init_askpass
            echo "Starting atsamd_fw_updater.sh with superuser rights..."
            sudo -A ./atsamd_fw_updater.sh $SERVICE_MENU_BASE_DIR
            sudo -A ./wait_disable_watchdog.sh $SERVICE_MENU_BASE_DIR
            read -s -n 1 -p "Press any key..."
            remove_askpass
        fi
        ;;
    3)
        ./internal_modules_menu.sh $SERVICE_MENU_BASE_DIR
        ;;
    4)
        ./external_modules_menu.sh $SERVICE_MENU_BASE_DIR
        ;;
    5)
        echo "shutting down machine..."
        sudo shutdown -P now
        ;;
    6)
        dialog --clear --defaultno --title "Leave service menu" --yesno "Are you sure?" 0 0

        if [ $? -eq 0 ]; then
            EXIT_FLAG=1
        fi
        ;;
    *)
        echo "restarting menu..."
        ;;
esac

done

exit 0
