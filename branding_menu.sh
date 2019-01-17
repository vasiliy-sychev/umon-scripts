#!/bin/bash
# ---------------------------------------------------------------
# v1.0c
# Written by Vasiliy Sychev (zero.dn.ua [at] gmail.com)
# ---------------------------------------------------------------
# Changelog:
#
# v1.0c (2019.01.17)
# - Improved generation of askpass.sh file
#
# v1.0b (2018.12.14)
# - Added Anesmed logo (item #10)
#
# v1.0a (2018.12.12)
# - Added some messages
# - cp now called with '-v' option
#
# v1.0 (2018.11.14)
# - Initial release. Just works.
#

SCRIPT_VERSION="1.0c"
TMP_FILE="/tmp/branding_menu_value"
EMMC_DEV_NAME="mmcblk0"

# ---------------------------------------------------------------

dialog --clear --title "MON700 Branding Menu v${SCRIPT_VERSION}" --menu "Please select logo from list:" 0 0 0 1 "UTAS" 2 "Erenler" 3 "BME" 4 "Heidelco" 5 "MTC (MedTechCenter)" 6 "Liamed" 7 "MV" 8 "QMB (Quality Medical Business)" 9 "TMT" 10 "Anesmed" 2> $TMP_FILE

RESULT=$?
ITEM=$(cat $TMP_FILE)

clear

case $RESULT in
    0)
        echo -n "Item $ITEM selected, "
        ;;
    1)
        echo "Cancelled, exiting..."
        exit 0
        ;;
    *)
        echo "Internal error (or ESC button was pressed), exiting..."
        exit 1
        ;;
esac

case $ITEM in
    1)
        echo "switching to UTAS logo..."
        KERNEL_DIR_NAME="kernel"
        APP_LOGO_ID=1
        ;;
    2)
        echo "switching to Erenler logo..."
        KERNEL_DIR_NAME="kernel-erenler"
        APP_LOGO_ID=2
        ;;
    3)
        echo "switching to BME logo..."
        KERNEL_DIR_NAME="kernel-bme"
        APP_LOGO_ID=3
        ;;
    4)
        echo "switching to Heidelco logo..."
        KERNEL_DIR_NAME="kernel-heidelco"
        APP_LOGO_ID=4
        ;;
    5)
        echo "switching to MedTechCenter logo..."
        KERNEL_DIR_NAME="kernel-mtc"
        APP_LOGO_ID=5
        ;;
    6)
        echo "switching to Liamed logo..."
        KERNEL_DIR_NAME="kernel-liamed"
        APP_LOGO_ID=6
        ;;
    7)
        echo "switching to MV logo..."
        KERNEL_DIR_NAME="kernel-mv"
        APP_LOGO_ID=1
        ;;
    8)
        echo "switching to QMB logo..."
        KERNEL_DIR_NAME="kernel-qmb"
        APP_LOGO_ID=1
        ;;
    9)
        echo "switching to TMT logo..."
        KERNEL_DIR_NAME="kernel-tmt"
        APP_LOGO_ID=1
        ;;
    10)
        echo "switching to Anesmed logo..."
        KERNEL_DIR_NAME="kernel-anesmed"
        APP_LOGO_ID=7
        ;;
    *)
        echo "exiting..."
        exit 1
        ;;
esac

# ---------------------------------------------------------------

echo "#!/bin/bash" > /tmp/askpass.sh
echo "echo Boundary" >> /tmp/askpass.sh
chmod 755 /tmp/askpass.sh

export SUDO_ASKPASS=/tmp/askpass.sh

# ---------------------------------------------------------------

echo "Unmounting partitions..."
sudo -A umount /dev/${EMMC_DEV_NAME}p1
sudo -A umount /dev/${EMMC_DEV_NAME}p2

# ---------------------------------------------------------------

echo "Mounting boot partition ${EMMC_DEV_NAME}p1..."
sudo -A mount /dev/${EMMC_DEV_NAME}p1 /media/debian/boot

if [ "$?" != "0" ]; then
    echo "Error mounting partition 1"
    exit 1
fi

# ---------------------------------------------------------------

echo "Mounting boot partition ${EMMC_DEV_NAME}p2..."
sudo -A mount /dev/${EMMC_DEV_NAME}p2 /media/debian/rootfs

if [ "$?" != "0" ]; then
    echo "Error mounting partition 2"
    
    sudo -A umount /dev/${EMMC_DEV_NAME}p1
    exit 1
fi

# ---------------------------------------------------------------

echo "Copying kernel from ${KERNEL_DIR_NAME}..."
sudo -A rm /media/debian/boot/zImage 2> /dev/null
sudo -A cp -v $KERNEL_DIR_NAME/zImage /media/debian/boot/zImage

if [ "$?" != "0" ]; then
    echo "Error copying kernel, unmounting partitions..."

    sudo -A umount /dev/${EMMC_DEV_NAME}p1
    sudo -A umount /dev/${EMMC_DEV_NAME}p2
    exit 1
fi

echo "Generating utas.vars file..."
echo "export MON700_LOGO=${APP_LOGO_ID}" > /tmp/utas.vars
sudo -A cp -v /tmp/utas.vars /media/debian/rootfs/etc/

echo "Syncing disks..."
sync

echo "Unmounting partitions..."
sudo -A umount /dev/${EMMC_DEV_NAME}p1
sudo -A umount /dev/${EMMC_DEV_NAME}p2

echo "Done!"
exit 0
