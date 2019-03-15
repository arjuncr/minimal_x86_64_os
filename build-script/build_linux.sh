#!/bin/bash
# ******************************************************************************
# LIGHT LINUX - 2019.2
# ******************************************************************************

SCRIPT_NAME="LIGHT LINUX BUILD SCRIPT"
SCRIPT_VERSION="1.0"
LINUX_NAME="LIGHT LINUX"
DISTRIBUTION_VERSION="2019.2"
ISO_FILENAME="light_linux-${SCRIPT_VERSION}.iso"

# BASE
KERNEL_BRANCH="4.x" 
KERNEL_VERSION="4.18.5"
BUSYBOX_VERSION="1.30.1"
SYSLINUX_VERSION="6.03"

# EXTRAS
NCURSES_VERSION="6.1"


BASEDIR=`realpath --no-symlinks $PWD`
SOURCEDIR=${BASEDIR}/sources
ROOTFSDIR=${BASEDIR}/rootfs
ISODIR=${BASEDIR}/iso

CFLAGS="-march=native -O2 -pipe"
CXXFLAGS="-march=native -O2 -pipe"
JFLAG=4

MENU_ITEM_SELECTED=0
DIALOG_OUT=/tmp/dialog_$$

# ******************************************************************************
# DIALOG FUNCTIONS
# ******************************************************************************

show_main_menu () {
    dialog --backtitle "${SCRIPT_NAME} - ${DISTRIBUTION_VERSION} / v${SCRIPT_VERSION}" \
    --title "MAIN MENU" \
    --default-item "${1}" \
    --menu "Lets build ${LINUX_NAME} operating Operating System v${SCRIPT_VERSION}" 18 64 10 \
    0 "INTRODUCTION" \
    1 "PREPARE DIRECTORIES" \
    2 "BUILD KERNEL" \
    3 "BUILD BUSYBOX" \
    4 "BUILD EXTRAS" \
    5 "GENERATE ROOTFS" \
    6 "GENERATE ISO" \
    7 "TEST IMAGE IN QEMU" \
    8 "CLEAN FILES" \
    9 "QUIT" 2> ${DIALOG_OUT}
}

show_dialog () {
    if [ ${#2} -le 24 ]; then
    WIDTH=24; HEIGHT=6; else
    WIDTH=64; HEIGHT=14; fi
    dialog --backtitle "${SCRIPT_NAME} - ${DISTRIBUTION_VERSION} / v${SCRIPT_VERSION}" \
    --title "${1}" \
    --msgbox "${2}" ${HEIGHT} ${WIDTH}
}

ask_dialog () {
    dialog --stdout \
    --backtitle "${SCRIPT_NAME} - ${DISTRIBUTION_VERSION} / v${SCRIPT_VERSION}" \
    --title "${1}" \
    --yesno "${2}" 14 64
}

check_error_dialog () {
    if [ $? -gt 0 ];
    then
        show_dialog "An error occured ;o" "There was a problem with ${1}.\nCheck the console output. Fix the problem and come back to the last step."
        exit
    fi
}

# ******************************************************************************
# MENUS
# ******************************************************************************

menu_introduction () {
    show_dialog "INTRODUCTION" "${LINUX_NAME} is an light linux based os" \
    && MENU_ITEM_SELECTED=1
    return 0
}

menu_prepare_dirs () {
    ask_dialog "PREPARE DIRECTORIES" "Create empty folders to work with.\n - /sources for all the source code\n - /rootfs for our root tree\n - /iso for ISO file" \
    && prepare_dirs \
    && MENU_ITEM_SELECTED=2 \
    && show_dialog "PREPARE DIRECTORIES" "Done."
    return 0
}

menu_build_kernel () {
    ask_dialog "BUILD KERNEL" "Linux Kernel ${KERNEL_VERSION} - this is the hearth of the operating system.\n\nRecipe:\n - download and extract\n - configure\n - build" \
    && build_kernel \
    && MENU_ITEM_SELECTED=3 \
    && show_dialog "BUILD KERNEL" "Done."
    return 0
}
menu_build_busybox () {
    ask_dialog "BUILD BUSYBOX" "Build BusyBox ${BUSYBOX_VERSION} - all the basic stuff like cp, ls, etc.\n\nRecipe:\n - download and extract\n - configure\n - build" \
    && build_busybox \
    && MENU_ITEM_SELECTED=4 \
    && show_dialog "BUILD BUSYBOX" "Done."
    return 0
}

menu_build_extras () {
    ask_dialog "BUILD EXTRAS" "Build extra soft" \
    && build_extras \
    && MENU_ITEM_SELECTED=5 \
    && show_dialog "BUILD EXTRAS" "Done."
    return 0
}

menu_generate_rootfs () {
    ask_dialog "GENERATE ROOTFS" "Generate root file system. Combines all of the created files in a one directory tree.\n\nRecipe:\n - generates default /etc files (configs).\n - compress file tree" \
    && generate_rootfs \
    && MENU_ITEM_SELECTED=6 \
    && show_dialog "GENERATE ROOTFS" "Done."
    return 0
}

menu_generate_iso () {
    ask_dialog "GENERATE ISO" "Generate ISO image to boot from.\n\nRecipe:\n - download SysLinux \n - copy nessesary files to ISO directory\n - build image" \
    && generate_iso \
    && MENU_ITEM_SELECTED=7 \
    && show_dialog "GENERATE ISO" "Done."
    return 0
}

menu_qemu () {
    ask_dialog "TEST IMAGE IN QEMU" "Test generated image on emulated computer (QEMU):\n - x86_64\n - 128MB ram\n - cdrom\n\nLOGIN: root\nPASSWORD: root" \
    && test_qemu \
    && MENU_ITEM_SELECTED=8 \
    && show_dialog "TEST IMAGE IN QEMU" "Done."
    return 0
}

menu_clean () {
    ask_dialog "CLEAN FILES" "Remove all archives, sources and temporary files." \
    && clean_files \
    && MENU_ITEM_SELECTED=9 \
    && show_dialog "CLEAN FILES" "Done."
    return 0
}


loop_menu () {
    show_main_menu ${MENU_ITEM_SELECTED}
    choice=$(cat ${DIALOG_OUT})

    case $choice in
        0) menu_introduction && loop_menu ;;
        1) menu_prepare_dirs && loop_menu ;;
        2) menu_build_kernel && loop_menu ;;
        3) menu_build_busybox && loop_menu ;;
        4) menu_build_extras && loop_menu ;;
        5) menu_generate_rootfs && loop_menu ;;
        6) menu_generate_iso && loop_menu ;;
        7) menu_qemu && loop_menu ;;
        8) menu_clean && loop_menu ;;
        9) exit;;
    esac
}

# ******************************************************************************
# MAGIC HAPPENS HERE
# ******************************************************************************

prepare_dirs () {
    cd ${BASEDIR}
    if [ ! -d ${SOURCEDIR} ];
    then
        mkdir ${SOURCEDIR}
    fi
    if [ ! -d ${ROOTFSDIR} ];
    then
        mkdir ${ROOTFSDIR}
    fi
    if [ ! -d ${ISODIR} ];
    then
        mkdir ${ISODIR}
    fi
}

build_kernel () {
    cd ${SOURCEDIR}
			
    cd linux-${KERNEL_VERSION}
    make clean
    make defconfig \
        -j ${JFLAG}
    sed -i "s/.*CONFIG_DEFAULT_HOSTNAME.*/CONFIG_DEFAULT_HOSTNAME=\"${LINUX_NAME}\"/" .config
    sed -i "s/.*CONFIG_FB_VESA.*/CONFIG_FB_VESA=y/" .config
    sed -i "s/.*LOGO_LINUX_CLUT224.*/LOGO_LINUX_CLUT224=y/" .config
    cp ${BASEDIR}/rattie_logo_224.ppm drivers/video/logo/logo_linux_clut224.ppm
    sed -i "s/.*CONFIG_OVERLAY_FS.*/CONFIG_OVERLAY_FS=y/" .config

    make bzImage \
        -j ${JFLAG}
     cp arch/x86/boot/bzImage ${ISODIR}/kernel.gz

    check_error_dialog "linux-${KERNEL_VERSION}"
}

build_busybox () {
    cd ${SOURCEDIR}

    cd busybox-${BUSYBOX_VERSION}
    make clean
    make defconfig
    sed -i 's|.*CONFIG_STATIC.*|CONFIG_STATIC=y|' .config
    make busybox \
        -j ${JFLAG}

    make install \
        -j ${JFLAG}

    rm -rf ${ROOTFSDIR} && mkdir ${ROOTFSDIR}
    cd _install
    cp -R . ${ROOTFSDIR}

    check_error_dialog "busybox-${BUSYBOX_VERSION}"
}

build_extras () {
    build_ncurses

    check_error_dialog "Building extras"

}

build_ncurses () {
    cd ${SOURCEDIR}
    
    cd ncurses-${NCURSES_VERSION}
    
    if [ -f Makefile ] ; then
        make -j ${JFLAG} clean
    fi
    sed -i '/LIBTOOL_INSTALL/d' c++/Makefile.in
    CFLAGS="${CFLAGS}" ./configure \
        --prefix=/usr \
        --with-termlib \
        --with-terminfo-dirs=/lib/terminfo \
        --with-default-terminfo-dirs=/lib/terminfo \
        --without-normal \
        --without-debug \
        --without-cxx-binding \
        --with-abi-version=5 \
        --enable-widec \
        --enable-pc-files \
        --with-shared \
        CPPFLAGS=-I$PWD/ncurses/widechar \
        LDFLAGS=-L$PWD/lib \
        CPPFLAGS="-P"

    make -j ${JFLAG}
    make install -j ${JFLAG}  \
        DESTDIR=${ROOTFSDIR}
    check_error_dialog "ncurses-${NCURSES_VERSION}"
}

build_nano () {
    cd ${SOURCEDIR}

    cd nano-${NANO_VERSION}
    if [ -f Makefile ] ; then
            make -j ${JFLAG} clean
    fi
    CFLAGS="${CFLAGS}" ./configure \
        --prefix=/usr \
        LDFLAGS=-L$PWD/lib

    make -j ${JFLAG}
    make install -j ${JFLAG} \
        DESTDIR=${ROOTFSDIR}

    check_error_dialog "nano-${NANO_VERSION}"
}

build_vim () {
    cd ${SOURCEDIR}

    cd vim${VIM_DIR}
    if [ -f Makefile ] ; then
            make -j ${JFLAG} clean
    fi
    CFLAGS="${CFLAGS}" ./configure \
        --prefix=/usr \
        LDFLAGS=-L$PWD/lib

    make -j ${JFLAG}
    make install \
        -j ${JFLAG} \
        DESTDIR=${ROOTFSDIR}

    check_error_dialog "vim-${VIM_VERSION}"
}


generate_rootfs () {
    cd ${ROOTFSDIR}
    rm -f linuxrc

    mkdir dev
    mkdir etc
    mkdir proc
    mkdir src
    mkdir sys
    mkdir tmp && chmod 1777 tmp

    cd etc
    touch motd
    echo >> motd
    echo ' ------------------------------------ 2019.2 ' >> motd
    echo '                   "..^__                    ' >> motd
    echo '                   *,,-,_).-~                ' >> motd
    echo '                 LIGHT LINUX                 ' >> motd
    echo '                                             ' >> motd
    echo '  ------------------------------------------ ' >> motd
    echo >> motd

    touch bootscript.sh
    echo '#!/bin/sh' >> bootscript.sh
    echo 'dmesg -n 1' >> bootscript.sh
    echo 'mount -t devtmpfs none /dev' >> bootscript.sh
    echo 'mount -t proc none /proc' >> bootscript.sh
    echo 'mount -t sysfs none /sys' >> bootscript.sh
    echo >> bootscript.sh
    chmod +x bootscript.sh

    touch inittab
    echo '::sysinit:/etc/bootscript.sh' >> inittab
    echo '::restart:/sbin/init' >> inittab
    echo '::ctrlaltdel:/sbin/reboot' >> inittab
    echo '::once:cat /etc/motd' >> inittab
    echo '::askfirst:-/bin/login' >> inittab
    echo 'tty2::once:cat /etc/motd' >> inittab
    echo 'tty2::askfirst:-/bin/sh' >> inittab
    echo 'tty3::once:cat /etc/motd' >> inittab
    echo 'tty3::askfirst:-/bin/sh' >> inittab
    echo 'tty4::once:cat /etc/motd' >> inittab
    echo 'tty4::askfirst:-/bin/sh' >> inittab
    echo >> inittab

    touch group
    echo 'root:x:0:root' >> group
    echo >> group

    touch passwd
    echo 'root:R.8MSU0Z/1ttM:0:0:Light Linux,,,:/root:/bin/sh' >> passwd
    echo >> passwd

    cd ${ROOTFSDIR}

    touch init
    echo '#!/bin/sh' >> init
    echo 'exec /sbin/init' >> init
    echo >> init
    chmod +x init

    # sudo chown -R root:root .
    find . | cpio -R root:root -H newc -o | gzip > ${ISODIR}/rootfs.gz

    check_error_dialog "rootfs"
}

generate_iso () {
    if [ ! -d ${SOURCEDIR}/syslinux-${SYSLINUX_VERSION} ];
    then
        cd ${SOURCEDIR}
        wget -O syslinux.tar.xz http://kernel.org/pub/linux/utils/boot/syslinux/syslinux-${SYSLINUX_VERSION}.tar.xz
        tar -xvf syslinux.tar.xz && rm syslinux.tar.xz
    fi
    cd ${SOURCEDIR}/syslinux-${SYSLINUX_VERSION}
    cp bios/core/isolinux.bin ${ISODIR}/
    cp bios/com32/elflink/ldlinux/ldlinux.c32 ${ISODIR}
    cp bios/com32/libutil/libutil.c32 ${ISODIR}
    cp bios/com32/menu/menu.c32 ${ISODIR}
    cd ${ISODIR}
    rm isolinux.cfg && touch isolinux.cfg
    echo 'default kernel.gz initrd=rootfs.gz vga=791' >> isolinux.cfg
    echo 'UI menu.c32 ' >> isolinux.cfg
    echo 'PROMPT 0 ' >> isolinux.cfg
    echo >> isolinux.cfg
    echo 'MENU TITLE LIGHT LINUX 2019.2 /'${SCRIPT_VERSION}': ' >> isolinux.cfg
    echo 'TIMEOUT 60 ' >> isolinux.cfg
    echo 'DEFAULT light linux ' >> isolinux.cfg
    echo >> isolinux.cfg
    echo 'LABEL light linux ' >> isolinux.cfg
    echo ' MENU LABEL START LIGHT LINUX [KERNEL:'${KERNEL_VERSION}']' >> isolinux.cfg
    echo ' KERNEL kernel.gz ' >> isolinux.cfg
    echo ' APPEND initrd=rootfs.gz vga=791 ' >> isolinux.cfg
    echo >> isolinux.cfg
    echo 'LABEL light_linux_vga ' >> isolinux.cfg
    echo ' MENU LABEL CHOOSE RESOLUTION ' >> isolinux.cfg
    echo ' KERNEL kernel.gz ' >> isolinux.cfg
    echo ' APPEND initrd=rootfs.gz vga=ask ' >> isolinux.cfg

    rm ${BASEDIR}/${ISO_FILENAME}

    xorriso \
        -as mkisofs \
        -o ${BASEDIR}/${ISO_FILENAME} \
        -b isolinux.bin \
        -c boot.cat \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        ./

    check_error_dialog "generating ISO"
}


test_qemu () {
    cd ${BASEDIR}
    if [ -f ${ISO_FILENAME} ];
    then
        qemu-system-x86_64 -m 128M -cdrom ${ISO_FILENAME} -boot d -vga std
    fi
    check_error_dialog "${ISO_FILENAME}"
}

clean_files () {
    sudo rm -rf ${SOURCEDIR}
    sudo rm -rf ${ROOTFSDIR}
    sudo rm -rf ${ISODIR}
}

# ******************************************************************************
# RUN SCRIPT
# ******************************************************************************

set -ex
loop_menu
set -ex

# ******************************************************************************
# EOF
# ******************************************************************************

