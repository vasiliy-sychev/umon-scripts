#!/bin/bash
# ---------------------------------------------------------------
# v1.2c
# Written by Vasiliy Sychev (zero.dn.ua [at] gmail.com)
# ---------------------------------------------------------------
# Changelog:
#
# v1.2d (2018.01.24)
# - Changed file name generation:
#   "uSD_xx_" -> "mon7xx_" where xx - display size
#   "_Solo512_" -> "_solo_"
#   "_Dual512_" -> "_dual_"
#   "_Quad1G_" -> "_quad1g_"
#   "_Quad2G_" -> "_quad2g_"
#
# v1.2c (2018.01.22)
# - Added copying of copy-elmiko-files.sh
# - Added copying of elmico dir
#
# v1.2b (2018.11.22)
# - Added optional function for replacing mon650.xxx binaries in generated image (can be actiavted
#   by MON700_APP_OVERLAY_PATH env variable).
#
# v1.2a (2018.11.21)
# - Removed workaround for Quad 1G CPU boards and 
#
# v1.2 (2018.11.16)
# - All file names and paths now will be full (absolute). Script can be called from everywhere,
#   and because of this, must be configured with shell env variables or command line arguments.
#   List of variables, used by this version:
#   - MON700_FS_SRC_PATH
#   - USD_BUILDER_OUT_DIR
# - Improved logging
#
# v1.1a (2018.10.25)
# - Fixed citical bug (added cp of necessary files)
# - mkdir output now will be redirected to /dev/null
#
# v1.1 (2018.10.22)
# - Added option (question) for writing generated image to SD card.
# - Added option (question) for creating compressed (zipped) image.
# - Some small fixes
#
# v1.0a (2018.10.19)
# - Added workaround for Quad 1G CPU boards (dedicated bootloader for uSD).
#
# v1.0 (2018.10.18)
# - Initial release. Just works.
#

SCRIPT_VERSION="1.2d"

# Default values
DEFAULT_BOOT_FS_FILENAME="fs_deb86_boot.tar.gz"
DEFAULT_SYS_FS_FILENAME="fs_deb86_current.tar.gz"
DEFAULT_IMG_SIZE=6144
DEFAULT_SD_DEV_PATH="/dev/sdb"
DEFAULT_COMPRESS_ANSWER="n"

# ---------------------------------------------------------------

if [ "$MON700_FS_SRC_PATH" = "" ]; then

if [ "$1" = "" ]; then
echo "Please set variable MON700_FS_SRC_PATH or supply it as first argument"
echo "Example: uSD_Builder.sh /home/user/MON700-FileSystem /home/user/uSD_Images"
exit 1
fi

MON700_FS_SRC_PATH=$1

fi

# ---------------------------------------------------------------

if [ "$USD_BUILDER_OUT_DIR" = "" ]; then

if [ "$2" = "" ]; then
echo "Please set variable USD_BUILDER_OUT_DIR or supply it as second argument"
echo "Example: uSD_Builder.sh /home/user/MON700-FileSystem /home/user/uSD_Images"
exit 1
fi

USD_BUILDER_OUT_DIR=$2

fi

# ---------------------------------------------------------------

if [ $(id -u) != "0" ]; then
echo "This script requires superuser rights. Please run as root"
exit 1
fi

# ---------------------------------------------------------------

clear
echo "Welcome to Interactive microSD Image Builder Script"
echo " "
echo "MON700_FS_SRC_PATH      = $MON700_FS_SRC_PATH"
echo "USD_BUILDER_OUT_DIR     = $USD_BUILDER_OUT_DIR"

if [ "$MON700_APP_OVERLAY_PATH" != "" ]; then
echo "MON700_APP_OVERLAY_PATH = $MON700_APP_OVERLAY_PATH"
fi

echo "---------------------------------------------"
echo "Step 1. Please select device model"
echo "(supported models: 10, 12, 15, 15W, 20)"

read -p "> " MON_MODEL

case $MON_MODEL in
	10)
		echo "10\" (1280x800, capacitive touch screen, alum case) selected"
		DISPLAY_RES="1280x800"
		ENV_FILE="mon715-1280x800-env.txt"
		;;
	12)
		echo "12\" (1024x768, resistive touch screen, plastic case) selected"
		DISPLAY_RES="1024x768"
		ENV_FILE="mon715-1024x768-env.txt"
		;;
	15)
		echo "15\" (1024x768, resistive touch screen, alum case) selected"
		DISPLAY_RES="1024x768"
		ENV_FILE="mon715-1024x768-env.txt"
		;;
	15W)
		echo "15\" Wide (1366x768, capacitive touch screen, alum case) selected"
		DISPLAY_RES="1366x768"
		ENV_FILE="mon715-1368x768-env.txt"
		;;
	20)
		echo "20\" (1920x1080, capacitive touch screen, alum case) selected"
		DISPLAY_RES="1920x1080"
		ENV_FILE="mon715-1920x1080-env.txt"
		;;
	*)
		echo "Unknown model. Please try again"
		exit 1
		;;
esac

# ---------------------------------------------------------------

echo " "
echo "Step 2. Please select CPU board/module"
echo "(supported boards: solo_512, dual_512, quad_1G, quad_2G)"

read -p "> " CPU_MODEL

case $CPU_MODEL in
	solo_512)
		echo "Single core with 512 MBytes of RAM selected"
		UBOOT_BIN_FN="u-boot-mon715-solo.imx"
		CPU_SHORT_NAME="solo"
		XORG_CONF="solo"
		;;
	dual_512)
		echo "Dual core (DualLite) with 512 MBytes of RAM selected"
		UBOOT_BIN_FN="u-boot-mon715-dual.imx"
		CPU_SHORT_NAME="dual"
		XORG_CONF="dl"
		;;
	quad_1G)
		echo "Quad core with 1024 MBytes of RAM selected"
		UBOOT_BIN_FN="u-boot-mon715-quad1G.imx"
		CPU_SHORT_NAME="quad1g"
		XORG_CONF="quad"
		;;
	quad_2G)
		echo "Quad core with 2048 MBytes of RAM selected"
		UBOOT_BIN_FN="u-boot-mon715-quad2G.imx"
		CPU_SHORT_NAME="quad2g"
		XORG_CONF="quad"
		;;
	*)
		echo "Unknown CPU board selected. Please try again"
		exit 1
		;;
esac

# ---------------------------------------------------------------

echo " "
echo "Step 3. Enter boot (live) OS filesystem image name (used for SD card)"
echo "(press ENTER to use default value \"${DEFAULT_BOOT_FS_FILENAME}\")"

read -p "> " BOOT_FS_FILENAME

if [ "$BOOT_FS_FILENAME" = "" ]; then
BOOT_FS_FILENAME=$DEFAULT_BOOT_FS_FILENAME
fi

# ---------------------------------------------------------------

echo " "
echo "Step 4. Enter device OS image name (used on UM-300)"
echo "(press ENTER to use default value \"${DEFAULT_SYS_FS_FILENAME}\")"

read -p "> " SYS_FS_FILENAME

if [ "$SYS_FS_FILENAME" = "" ]; then
SYS_FS_FILENAME=$DEFAULT_SYS_FS_FILENAME
fi

# ---------------------------------------------------------------

echo " "
echo "Step 5. Enter image size (megabytes)"
echo "Useful values: 4096, 5120, 6144, 7168, 8192, 9216, 10240, 11264"
echo "(press ENTER to use default value ${DEFAULT_IMG_SIZE}MB)"

read -p "> " IMG_SIZE_MBYTES

if [ "$IMG_SIZE_MBYTES" = "" ]; then
IMG_SIZE_MBYTES=$DEFAULT_IMG_SIZE
fi

# ---------------------------------------------------------------

echo " "
echo "Step 6. Write generated image to SD card? Type \"n\" or device name"
echo "(press ENTER to use default value \"${DEFAULT_SD_DEV_PATH}\")"

read -p "> " SD_DEV_PATH

if [ "$SD_DEV_PATH" = "" ]; then
SD_DEV_PATH=$DEFAULT_SD_DEV_PATH
elif [ "$SD_DEV_PATH" = "/dev/sda" ]; then
echo "Writing to device /dev/sda prohibited for your safety. Using value \"n\""
SD_DEV_PATH="n"
fi

# ---------------------------------------------------------------

echo " "
echo "Step 7. Compress created image with zip? Type \"y\" or \"n\""
echo "(press ENTER to use default value \"${DEFAULT_COMPRESS_ANSWER}\")"

read -p "> " COMPRESS_WITH_ZIP

if [ "$COMPRESS_WITH_ZIP" = "" ]; then
COMPRESS_WITH_ZIP=$DEFAULT_COMPRESS_ANSWER
fi

# ---------------------------------------------------------------

DATETIME=$(date +%Y%m%d_%H%M)

IMG_FILE="mon7${MON_MODEL}_${CPU_SHORT_NAME}_${DATETIME}.img"
LOG_FILE="mon7${MON_MODEL}_${CPU_SHORT_NAME}_${DATETIME}.log"
ZIP_FILE="mon7${MON_MODEL}_${CPU_SHORT_NAME}_${DATETIME}.zip"

LOG_FULL_FN=$USD_BUILDER_OUT_DIR/$LOG_FILE

# ---------------------------------------------------------------

clear
echo "Building microSD image ($IMG_FILE) with this settings:"
echo "Display resolution:           ${DISPLAY_RES}"
echo "X.Org config file:            xorg.conf.${XORG_CONF}"
echo "Bootloader (U-BOOT):          ${UBOOT_BIN_FN}"
echo "SD card OS filesystem image:  ${BOOT_FS_FILENAME}"
echo "UM-300 OS filesystem image:   ${SYS_FS_FILENAME}"
echo "Disk image size:              ${IMG_SIZE_MBYTES} megabytes"

if [ "$SD_DEV_PATH" != "n" ]; then
echo "Image will be written to:     ${SD_DEV_PATH}"
fi

if [ "$COMPRESS_WITH_ZIP" = "y" ]; then
echo "-----------------------------------------------------"
echo "Generated image will be compressed with zip"
fi

echo "-----------------------------------------------------"
echo "Continue? Type \"y\" or \"n\""
read -p "> " CONFIRM

if [ "$CONFIRM" != "y" ]; then
echo "Exiting..."
exit 0
fi

# ---------------------------------------------------------------
#           IMAGE GENERATION BEGINS AFTER THIS COMMENT
# ---------------------------------------------------------------

echo "*** Autogenerated by uSD_Builder.sh v${SCRIPT_VERSION} ***" > $LOG_FULL_FN
echo "--------------------------------------------------------"  >> $LOG_FULL_FN
echo "MON700_FS_SRC_PATH  = $MON700_FS_SRC_PATH"  >> $LOG_FULL_FN
echo "USD_BUILDER_OUT_DIR = $USD_BUILDER_OUT_DIR" >> $LOG_FULL_FN
echo "DISPLAY_RES         = $DISPLAY_RES"         >> $LOG_FULL_FN
echo "XORG_CONF           = $XORG_CONF"           >> $LOG_FULL_FN
echo "BOOT_FS_FILENAME    = $BOOT_FS_FILENAME"    >> $LOG_FULL_FN
echo "SYS_FS_FILENAME     = $SYS_FS_FILENAME"     >> $LOG_FULL_FN
echo "IMG_SIZE_MBYTES     = $IMG_SIZE_MBYTES"     >> $LOG_FULL_FN
echo "--------------------------------------------------------"  >> $LOG_FULL_FN

if [ "$MON700_APP_OVERLAY_PATH" != "" ]; then
echo "MON700_APP_OVERLAY_PATH = $MON700_APP_OVERLAY_PATH"        >> $LOG_FULL_FN
echo "--------------------------------------------------------"  >> $LOG_FULL_FN
fi

START_DATETIME=$(date "+%Y.%m.%d %H:%M")
echo "Image generation started at: $START_DATETIME" >> $LOG_FULL_FN

# ---------------------------------------------------------------

clear
echo "Creating new clean RAW image..."
dd if=/dev/zero of=$USD_BUILDER_OUT_DIR/$IMG_FILE bs=1048576 count=$IMG_SIZE_MBYTES status=progress

if [ "$?" != "0" ]; then
echo "Error creating RAW image. Please try again"
exit 1
fi

# ---------------------------------------------------------------

echo "Creating partitions..."

parted $USD_BUILDER_OUT_DIR/$IMG_FILE --script mklabel msdos

if [ "$?" != "0" ]; then
echo "Error creating DOS (MBR) partition table"
exit 1
fi

# Alignment == 8 MBytes
parted $USD_BUILDER_OUT_DIR/$IMG_FILE --script mkpart primary 16384s 32MiB

if [ "$?" != "0" ]; then
echo "Error creating partition 1"
exit 1
fi

parted $USD_BUILDER_OUT_DIR/$IMG_FILE --script mkpart primary 32MiB -- -1s

if [ "$?" != "0" ]; then
echo "Error creating partition 2"
exit 1
fi

# ---------------------------------------------------------------

echo "Copying bootloader ($UBOOT_BIN_FN)..."
echo "Bootloader for SD card:      u-boot/$UBOOT_BIN_FN" >> $LOG_FULL_FN
dd if=$MON700_FS_SRC_PATH/u-boot/$UBOOT_BIN_FN of=$USD_BUILDER_OUT_DIR/$IMG_FILE bs=512 seek=2 conv=nocreat,notrunc

if [ "$?" != "0" ]; then
echo "Error copying bootloader (U-BOOT)"
exit 1
fi

# ---------------------------------------------------------------

echo "Creating loop devices..."
KPARTX_OUTPUT=$(kpartx -a -s -v $USD_BUILDER_OUT_DIR/$IMG_FILE)

if [ "$?" != "0" ]; then
echo "Error mapping file as disk drives (kpartx call failed)"
exit 1
fi

#echo "[DEBUG] kpartx output:" $KPARTX_OUTPUT

LOOP_P1="${KPARTX_OUTPUT:8:7}"
echo "Partition 1 now known as \"${LOOP_P1}\""
LOOP_P2="${KPARTX_OUTPUT:58:7}"
echo "Partition 2 now known as \"${LOOP_P2}\""

# ---------------------------------------------------------------

echo "Creating file systems..."

mkfs.vfat /dev/mapper/$LOOP_P1

if [ "$?" != "0" ]; then
echo "Error creating FAT file system"
kpartx -d $USD_BUILDER_OUT_DIR/$IMG_FILE
exit 1
fi

mkfs.ext3 /dev/mapper/$LOOP_P2

if [ "$?" != "0" ]; then
echo "Error creating ext3 file system"
kpartx -d $USD_BUILDER_OUT_DIR/$IMG_FILE
exit 1
fi

echo "Syncing disks..."
sync

# ---------------------------------------------------------------

SD_P1_BOOT="/media/${USER}/uSD_boot"
SD_P2_ROOT="/media/${USER}/uSD_root"

echo "Mounting file systems..."

mkdir /media/$USER 2> /dev/null
mkdir $SD_P1_BOOT 2> /dev/null
mkdir $SD_P2_ROOT 2> /dev/null

echo "Mounting $LOOP_P1 to ${SD_P1_BOOT}..."
mount -t vfat /dev/mapper/$LOOP_P1 $SD_P1_BOOT

if [ "$?" != "0" ]; then
echo "Error mounting partition 1 (FAT)"
kpartx -d $USD_BUILDER_OUT_DIR/$IMG_FILE
exit 1
fi

echo "Mounting $LOOP_P2 to ${SD_P2_ROOT}..."
mount -t ext3 /dev/mapper/$LOOP_P2 $SD_P2_ROOT

if [ "$?" != "0" ]; then
echo "Error mounting partition 2 (ext3)"
umount /dev/mapper/$LOOP_P1
sync
kpartx -d $USD_BUILDER_OUT_DIR/$IMG_FILE
exit 1
fi

# ---------------------------------------------------------------
# COPYING FILES TO PARTITION 1

echo "Copying files to boot partition..."
echo "--------------------------------------------------------" >> $LOG_FULL_FN
echo "Copying files to first (boot) partition..." >> $LOG_FULL_FN

cp -v $MON700_FS_SRC_PATH/kernel/zImage     $SD_P1_BOOT/                >> $LOG_FULL_FN
cp -v $MON700_FS_SRC_PATH/u-boot/$ENV_FILE  $SD_P1_BOOT/mon715-env.txt  >> $LOG_FULL_FN
cp -R -v $MON700_FS_SRC_PATH/dtb/uni/*      $SD_P1_BOOT/                >> $LOG_FULL_FN

echo "Syncing disks..."
sync

echo "Unmounting uSD_boot (partition 1)..."
umount /dev/mapper/$LOOP_P1

# ---------------------------------------------------------------
# COPYING FILES TO PARTITION 2

echo "Unpacking ${BOOT_FS_FILENAME}..."
echo "--------------------------------------------------------" >> $LOG_FULL_FN
echo "Extracting data from ${BOOT_FS_FILENAME}..."              >> $LOG_FULL_FN
tar -zxpvf $MON700_FS_SRC_PATH/boot_fs/$BOOT_FS_FILENAME -C $SD_P2_ROOT --numeric-owner >> $LOG_FULL_FN

if [ "$?" != "0" ]; then
echo "Error unpacking bootable SD card OS image ($BOOT_FS_FILENAME)"
sync
umount /dev/mapper/$LOOP_P2
kpartx -d $USD_BUILDER_OUT_DIR/$IMG_FILE
exit 1
fi

echo "Copying files..."
echo "--------------------------------------------------------" >> $LOG_FULL_FN
echo "Copying files..."                                         >> $LOG_FULL_FN
cp -v $MON700_FS_SRC_PATH/xorg.conf.$XORG_CONF $SD_P2_ROOT/usr/share/vivante/X11/xorg.conf/xorg-mx6.conf >> $LOG_FULL_FN

rm -f -R $SD_P2_ROOT/home/debian/mon71x/fs/ 2> /dev/null
mkdir -p $SD_P2_ROOT/home/debian/mon71x/fs/ 2> /dev/null

cp -v $MON700_FS_SRC_PATH/fs/$SYS_FS_FILENAME          $SD_P2_ROOT/home/debian/mon71x/fs/ >> $LOG_FULL_FN

rm -R $SD_P2_ROOT/home/debian/mon71x/kernel/* 2> /dev/null

cp -R -p -v $MON700_FS_SRC_PATH/kernel*                $SD_P2_ROOT/home/debian/mon71x/ >> $LOG_FULL_FN
cp -R -p -v $MON700_FS_SRC_PATH/mon700-ini             $SD_P2_ROOT/home/debian/mon71x/ >> $LOG_FULL_FN
cp -R -p -v $MON700_FS_SRC_PATH/dtb                    $SD_P2_ROOT/home/debian/mon71x/ >> $LOG_FULL_FN
cp -R -p -v $MON700_FS_SRC_PATH/u-boot                 $SD_P2_ROOT/home/debian/mon71x/ >> $LOG_FULL_FN

cp -R -p -v $MON700_FS_SRC_PATH/kernel/*mod/*          $SD_P2_ROOT/ >> $LOG_FULL_FN

cp -R -p -v $MON700_FS_SRC_PATH/mon700-scripts-master  $SD_P2_ROOT/home/debian/mon71x/ >> $LOG_FULL_FN

cp -p -v $MON700_FS_SRC_PATH/test-menu.sh              $SD_P2_ROOT/home/debian/mon71x/test-menu.sh >> $LOG_FULL_FN
cp -p -v $MON700_FS_SRC_PATH/create_mon71*.sh          $SD_P2_ROOT/home/debian/mon71x/ >> $LOG_FULL_FN
cp -p -v $MON700_FS_SRC_PATH/restore-mon650-ini.sh     $SD_P2_ROOT/home/debian/mon71x/ >> $LOG_FULL_FN

echo "Deleting old scripts and tools..."
rm -rf $SD_P2_ROOT/home/debian/mon71x/mon700-tools 2> /dev/null
rm -rf $SD_P2_ROOT/home/debian/scripts 2> /dev/null
rm -rf $SD_P2_ROOT/home/debian/mon71x/app-mon715 2> /dev/null

echo "Copying new scripts and tools..."
cp -R -p -v $MON700_FS_SRC_PATH/mon700-scripts-master/home/debian/fw_mon700_tools  $SD_P2_ROOT/home/debian/mon71x/ >> $LOG_FULL_FN
cp -R -p -v $MON700_FS_SRC_PATH/mon700-scripts-master/home/debian/scripts          $SD_P2_ROOT/home/debian/ >> $LOG_FULL_FN
cp -R -p -v $MON700_FS_SRC_PATH/mon700-ini                                         $SD_P2_ROOT/home/debian/mon71x/ >> $LOG_FULL_FN
cp -R -p -v $MON700_FS_SRC_PATH/ftdi                                               $SD_P2_ROOT/home/debian/mon71x/ >> $LOG_FULL_FN

echo "Copying \"check board\" scripts..."
cp -p -v $MON700_FS_SRC_PATH/check*.sh                 $SD_P2_ROOT/home/debian/mon71x/ >> $LOG_FULL_FN

echo "Copying kernels with other LOGOS scripts..."
cp -p -v $MON700_FS_SRC_PATH/copy*kernel.sh            $SD_P2_ROOT/home/debian/mon71x/ >> $LOG_FULL_FN

echo "Copying \"apps and scripts copy script\"..."
cp -p -v $MON700_FS_SRC_PATH/copy-app-mon715-files.sh  $SD_P2_ROOT/home/debian/mon71x/ >> $LOG_FULL_FN

echo "Copying \"copy-elmiko-files.sh\"..."
cp -p -v $MON700_FS_SRC_PATH/copy-elmiko-files.sh  $SD_P2_ROOT/home/debian/mon71x/ >> $LOG_FULL_FN

echo "Copying \"elmico\" directory..."
cp -R -p -v $MON700_FS_SRC_PATH/elmico $SD_P2_ROOT/home/debian/mon71x/ >> $LOG_FULL_FN

echo "Copying openbox autostart..."
cp -p -v $MON700_FS_SRC_PATH/samd_wdt/autostart        $SD_P2_ROOT/home/debian/.config/openbox/ >> $LOG_FULL_FN

# ---------------------------------------------------------------
# Addons from ../MON700-FS-Addons

echo "Copying third-party addons..."
echo "--------------------------------------------------------" >> $LOG_FULL_FN
echo "Copying third-party addons..." >> $LOG_FULL_FN
cp -p -v $MON700_FS_SRC_PATH/../MON700-FS-Addons/* $SD_P2_ROOT/home/debian/mon71x/ >> $LOG_FULL_FN

# Bin replacement
if [ "$MON700_APP_OVERLAY_PATH" != "" ]; then
echo "Replacing mon650 application binaries..."
echo "--------------------------------------------------------" >> $LOG_FULL_FN
echo "Replacing mon650 application binaries..." >> $LOG_FULL_FN
cp -p -f -v $MON700_APP_OVERLAY_PATH/* $SD_P2_ROOT/home/debian/mon71x/mon700-scripts-master/home/debian/mon650/ >> $LOG_FULL_FN
fi

# ---------------------------------------------------------------

echo "Syncing disks..."
sync

echo "Unmounting uSD_root (partition 2)..."
umount /dev/mapper/$LOOP_P2

END_DATETIME=$(date "+%Y.%m.%d %H:%M")
echo "--------------------------------------------------------" >> $LOG_FULL_FN
echo "Image generation ended on: $END_DATETIME" >> $LOG_FULL_FN

kpartx -d $USD_BUILDER_OUT_DIR/$IMG_FILE
sync

echo "Done!"

# ---------------------------------------------------------------

if [ "$SD_DEV_PATH" = "/dev/sda" ]; then
echo "SD_DEV_PATH=${SD_DEV_PATH}, WTF?!"
elif [ "$SD_DEV_PATH" != "n" ]; then
echo "Writing image to SD card..."
dd if=$USD_BUILDER_OUT_DIR/$IMG_FILE of=$SD_DEV_PATH bs=1048576 status=progress
fi

# ---------------------------------------------------------------

if [ "$COMPRESS_WITH_ZIP" = "y" ]; then
echo "Creating compressed image, please wait..."
zip -j $USD_BUILDER_OUT_DIR/$ZIP_FILE $USD_BUILDER_OUT_DIR/$IMG_FILE $LOG_FULL_FN
fi

# ---------------------------------------------------------------

exit 0
