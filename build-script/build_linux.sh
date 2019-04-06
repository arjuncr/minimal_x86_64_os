#!/bin/bash
# ******************************************************************************
# LIGHT LINUX - 2019.4
# ******************************************************************************

SCRIPT_NAME="LIGHT LINUX BUILD SCRIPT"
SCRIPT_VERSION="1.0"
export LINUX_NAME="LIGHT LINUX"
export DISTRIBUTION_VERSION="2019.4"
export ISO_FILENAME="light_linux-${SCRIPT_VERSION}.iso"

# BASE
KERNEL_BRANCH="4.x" 
KERNEL_VERSION="4.18.5"
BUSYBOX_VERSION="1.30.1"
SYSLINUX_VERSION="6.03"

# EXTRAS
export NCURSES_VERSION="6.1"

export BASEDIR=`realpath --no-symlinks $PWD`
export SOURCEDIR=${BASEDIR}/sources
export ROOTFSDIR=${BASEDIR}/rootfs
export ISODIR=${BASEDIR}/iso
export BUILD_OTHER_DIR="build_script_for_other"
export BOOT_SCRIPT_DIR="boot_script"
export NET_SCRIPT="network"

export CROSS_COMPILE64=$BASEDIR/cross_gcc/x86_64-linux/bin/x86_64-linux-
export ARCH64="x86_64"
export CROSS_COMPILEi386=$BASEDIR/cross_gcc/i386-linux/bin/i386-linux-
export ARCHi386="i386"


export ETCDIR="etc"
export MODE="754"
export DIRMODE="755"
export CONFMODE="644"

export CFLAGS=-m64
export CXXFLAGS=-m64
export JFLAG=4

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
    ask_dialog "BUILD KERNEL" "Linux Kernel ${KERNEL_VERSION} - this is the hearth of the operating system.\n\nRecipe:\n - configure\n - build" \
    && build_kernel \
    && MENU_ITEM_SELECTED=3 \
    && show_dialog "BUILD KERNEL" "Done."
    return 0
}
menu_build_busybox () {
    ask_dialog "BUILD BUSYBOX" "Build BusyBox ${BUSYBOX_VERSION} - all the basic stuff like cp, ls, etc.\n\nRecipe:\n - configure\n - build" \
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
    make CROSS_COMPILE=$CROSS_COMPILE64 ARCH=$ARCH64 x86_64_defconfig \
        -j ${JFLAG}
    sed -i "s/.*CONFIG_DEFAULT_HOSTNAME.*/CONFIG_DEFAULT_HOSTNAME=\"${LINUX_NAME}\"/" .config
	
    make modules_install CROSS_COMPILE=$CROSS_COMPILE64 ARCH=$ARCH64 -j ${JFLAG}

    make CROSS_COMPILE=$CROSS_COMPILE64 ARCH=$ARCH64 bzImage \
        -j ${JFLAG}
     cp arch/$ARCH64/boot/bzImage ${ISODIR}/kernel.gz

    check_error_dialog "linux-${KERNEL_VERSION}"
}

build_busybox () {
    cd ${SOURCEDIR}

    cd busybox-${BUSYBOX_VERSION}
    make clean
    make CROSS_COMPILE=$CROSS_COMPILE64 ARCH=$ARCH64  x86_64_defconfig
    sed -i 's|.*CONFIG_STATIC.*|CONFIG_STATIC=y|' .config
    make CROSS_COMPILE=$CROSS_COMPILE64 ARCH=$ARCH64  busybox \
        -j ${JFLAG}

    make CROSS_COMPILE=$CROSS_COMPILE64 ARCH=$ARCH64 install \
        -j ${JFLAG}

    rm -rf ${ROOTFSDIR} && mkdir ${ROOTFSDIR}
    cd _install
    cp -R . ${ROOTFSDIR}

    check_error_dialog "busybox-${BUSYBOX_VERSION}"
}

build_extras () {
   # build_ncurses
   cd ${BASEDIR}/${BUILD_OTHER_DIR}
   ./build_other_main.sh

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

    make CROSS_COMPILE=$CROSS_COMPILE64 ARCH=$ARCH64 -j ${JFLAG}
    make CROSS_COMPILE=$CROSS_COMPILE64 ARCH=$ARCH64 install -j ${JFLAG}  \
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

    make CROSS_COMPILE=$CROSS_COMPILE64 ARCH=$ARCH64 -j ${JFLAG}
    make CROSS_COMPILE=$CROSS_COMPILE64 ARCH=$ARCH64 install -j ${JFLAG} \
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

    make CROSS_COMPILE=$CROSS_COMPILE64 ARCH=$ARCH64 -j ${JFLAG}
    make CROSS_COMPILE=$CROSS_COMPILE64 ARCH=$ARCH64 install \
        -j ${JFLAG} \
        DESTDIR=${ROOTFSDIR}

    check_error_dialog "vim-${VIM_VERSION}"
}


generate_rootfs () {	
    cd ${ROOTFSDIR}
    #rm -f linuxrc

    mkdir dev
    mkdir etc
    mkdir proc
    mkdir src
    mkdir sys
    mkdir var
    mkdir var/log
    mkdir srv
    mkdir run
    mkdir lib
    mkdir root
    mkdir boot
    mkdir tmp && chmod 1777 tmp

    mkdir -pv usr/{,local/}{bin,include,lib{,64},sbin,src}
    mkdir -pv usr/{,local/}share/{doc,info,locale,man}
    mkdir -pv usr/{,local/}share/{misc,terminfo,zoneinfo}      
    mkdir -pv usr/{,local/}share/man/man{1,2,3,4,5,6,7,8}
    mkdir -pv etc/rc{0,1,2,3,4,5,6,S}.d
    mkdir -pv etc/init.d

    cd etc

    if [ -f motd ]
    then
        rm motd
    fi

    touch motd
    echo >> motd
    echo ' ------------------------------------ 2019.2 ' >> motd
    echo '                   "..^__                    ' >> motd
    echo '                   *,,-,_).-~                ' >> motd
    echo '                 LIGHT LINUX                 ' >> motd
    echo '                                             ' >> motd
    echo '  ------------------------------------------ ' >> motd
    echo >> motd
	
    if [ -f hosts ]
    then
        rm hosts
    fi
    echo '127.0.0.1 lcalhost'>>hosts

    if [ -f resolv.conf ]
    then
        rm resolv.conf
    fi

    echo 'nameserver 8.8.8.8'>>resolv.conf
    echo 'nameserver 8.8.4.4'>>resolv.conf

    if [ -f fstab ]
    then
	rm fstab
    fi	

    touch fstab
    echo '# file system  mount-point  type   options          dump   fsck'  >>fstab
    echo '#                                                          order' >>fstab
    echo 'rootfs          /               auto    defaults        1      1' >>fstab
    echo 'proc            /proc           proc    defaults        0      0' >>fstab
    echo 'sysfs           /sys            sysfs   defaults        0      0' >>fstab
    echo 'devpts          /dev/pts        devpts  gid=4,mode=620  0      0' >>fstab
    echo 'tmpfs           /dev/shm        tmpfs   defaults        0      0' >>fstab

    # touch bootscript.sh
    # echo '#!/bin/sh' >> bootscript.sh
    # echo 'dmesg -n 1' >> bootscript.sh
    # echo 'mount -t devtmpfs none /dev' >> bootscript.sh
    # echo 'mount -t proc none /proc' >> bootscript.sh
    # echo 'mount -t sysfs none /sys' >> bootscript.sh
    # echo >> bootscript.sh
    # chmod +x bootscript.sh

    rm -r init.d/*

    install -m ${CONFMODE} ${BASEDIR}/${BOOT_SCRIPT_DIR}/rc.d/init.d/functions     init.d/functions
    install -m ${CONFMODE} ${BASEDIR}/${BOOT_SCRIPT_DIR}/rc.d/init.d/network	   init.d/network
    install -m ${MODE}     ${BASEDIR}/${BOOT_SCRIPT_DIR}/rc.d/startup              init.d/startup
    install -m ${MODE}     ${BASEDIR}/${BOOT_SCRIPT_DIR}/rc.d/shutdown             init.d/shutdown

    chmod +x init.d/*

    ln -s init.d/network   rc0.d/K01network
    ln -s init.d/network   rc1.d/K01network
    ln -s init.d/network   rc2.d/S01network
    ln -s init.d/network   rc3.d/S01network
    ln -s init.d/network   rc4.d/S01network
    ln -s init.d/network   rc5.d/S01network
    ln -s init.d/network   rc6.d/K01network
    ln -s init.d/network   rcS.d/S01network

    #Network configuration
    cp -r ${BASEDIR}/${NET_SCRIPT}                                                 ./
	
    if [ -f inittab ]
    then
        rm inittab
    fi

    touch inittab
    echo '::sysinit:/etc/init.d/startup' >> inittab
    echo '::restart:/sbin/init' >> inittab
    echo '::shutdown:/etc/init.d/shutdown' >>inittab
    echo '::ctrlaltdel:/sbin/reboot' >> inittab
    echo '::once:cat /etc/motd' >> inittab
    echo '::askfirst:-/bin/login' >> inittab
    echo 'tty2::respawn:/sbin/getty 38400 tty2' >> inittab
    echo 'tty3::respawn:/sbin/getty 38400 tty3' >> inittab
    echo 'tty4::respawn:/sbin/getty 38400 tty4' >> inittab
    echo >> inittab

    if [ -f group ]
    then
        rm group
    fi

    touch group
    echo 'root:x:0:root' >> group
    echo 'root:x:0:'     >>group
    echo 'bin:x:1:'      >>group
    echo 'sys:x:2:'      >>group
    echo 'kmem:x:3:'     >>group
    echo 'tty:x:4:'      >>group
    echo 'daemon:x:6:'   >>group
    echo 'disk:x:8:'     >>group
    echo 'dialout:x:10:' >>group
    echo 'video:x:12:'   >>group
    echo 'utmp:x:13:'    >>group
    echo 'usb:x:14:'     >>group
    echo >> group
	
    if [ -f passwd ]
    then
        rm passwd
    fi

    touch passwd
    echo 'root:R.8MSU0Z/1ttM:0:0:Light Linux,,,:/root:/bin/sh' >> passwd
    echo >> passwd

    cd ${ROOTFSDIR}
    
    if [ -f init ]
    then
        rm init
    fi

    touch init
    echo '#!/bin/sh' >> init
    echo 'exec /sbin/init' >> init
    echo >> init
    chmod +x init

    #creating initial device node
    mknod -m 622 dev/console c 5 1
    mknod -m 666 dev/null c 1 3
    mknod -m 666 dev/zero c 1 5
    mknod -m 666 dev/ptmx c 5 2
    mknod -m 666 dev/tty c 5 0
    mknod -m 666 dev/tty1 c 4 1
    mknod -m 666 dev/tty2 c 4 2
    mknod -m 666 dev/tty3 c 4 3
    mknod -m 666 dev/tty4 c 4 4
    mknod -m 444 dev/random c 1 8
    mknod -m 444 dev/urandom c 1 9
    mknod -m 666 dev/ram b 1 1
    mknod -m 666 dev/mem c 1 1
    mknod -m 666 dev/kmem c 1 2
    chown root:tty dev/{console,ptmx,tty,tty1,tty2,tty3,tty4}

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
    echo 'MENU TITLE LIGHT LINUX 2019.4 /'${SCRIPT_VERSION}': ' >> isolinux.cfg
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

