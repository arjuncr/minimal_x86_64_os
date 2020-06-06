# @author ARJUN C R (arjuncr00@acrlinux.com)
#
# web site https://www.acrlinux.com
#
#!/bin/bash

int_build_env()
{
export VERSION="1.5"
export SCRIPT_NAME="ACR LINUX BUILD SCRIPT"
export SCRIPT_VERSION="1.5"
export LINUX_NAME="acr-linux"
export DISTRIBUTION_VERSION="2020.5"

# BASE
export KERNEL_BRANCH="5.x" 
export KERNEL_VERSION="5.6.14"
export BUSYBOX_VERSION="1.30.1"
export SYSLINUX_VERSION="6.03"

# EXTRAS
export NCURSES_VERSION="6.1"
export NANO_VERSION="4.0"
export VIM_DIR="81"

export BASEDIR=`realpath --no-symlinks $PWD`
export SOURCEDIR=${BASEDIR}/light-os
export ROOTFSDIR=${BASEDIR}/rootfs
export ISODIR=${BASEDIR}/iso
export TARGETDIR=${BASEDIR}/debian-target/rootfs_x86_64
export BASE_ROOTFS=${BASEDIR}/base-rootfs
export BUILD_OTHER_DIR="build_script_for_other"
export BOOT_SCRIPT_DIR="boot_script"
export NET_SCRIPT="network"
export CONFIG_ETC_DIR="${BASEDIR}/os-configs/etc"
export WORKSPACE="${BASEDIR}/workspace"

#cross compile
export CROSS_COMPILE64=$BASEDIR/cross_gcc/x86_64-linux/bin/x86_64-linux-
export ARCH64="x86_64"
export CROSS_COMPILEi386=$BASEDIR/cross_gcc/i386-linux/bin/i386-linux-
export ARCHi386="i386"

if [ "$3" == "64" ]
then
export ARCH = $ARCH64
export CROSS_COMPILE = $CROSS_COMPILE64
elif [ "$3" == "32" ]
then
export ARCH = $ARCHi386
export CROSS_COMPILE = $CROSS_COMPILEi386
else
export ARCH = $ARCH64
export CROSS_COMPILE = $CROSS_COMPILE64
fi

export ISO_FILENAME="minimal-acrlinux-${ARCH}-${SCRIPT_VERSION}.iso"

#Dir and mode
export ETCDIR="etc"
export MODE="754"
export DIRMODE="755"
export CONFMODE="644"

#configs
export LIGHT_OS_KCONFIG="$BASEDIR/configs/kernel/light_os_kconfig"
export LIGHT_OS_BUSYBOX_CONFIG="$BASEDIR/configs/busybox/light_os_busybox_config"

#cflags
export CFLAGS=-m64
export CXXFLAGS=-m64

#setting JFLAG
if [ -z "$2"  ]
then	
	export JFLAG=4
else
	export JFLAG=$2
fi

}

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
        mkdir    ${ISODIR}
    fi
    if [ ! -d ${WORKSPACE} ];
    then
	mkdir ${WORKSPACE}
    fi
}

build_kernel () {
    cd ${SOURCEDIR}

    if [ ! -d ${WORKSPACE}/linux-${KERNEL_VERSION} ];
    then
	    echo "copying kernel src to workspace"
	    cp -r linux-${KERNEL_VERSION} ${WORKSPACE}
	    echo "copying kernel patch to workspace"
	    cp -r kernel-patch ${WORKSPACE}
	    cd  ${WORKSPACE}/linux-${KERNEL_VERSION}
	    for patch in $(ls ../kernel-patch | grep '^[000-999]*_.*.patch'); do
		    echo "applying patch .... '$patch'."
		    patch -p1 < ../kernel-patch/${patch}
            done
    fi

    cd  ${WORKSPACE}/linux-${KERNEL_VERSION}
	
    if [ "$1" == "-c" ]
    then		    
    	make clean -j$JFLAG ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE
    elif [ "$1" == "-b" ]
    then	    
    	 cp $LIGHT_OS_KCONFIG .config
    	 make oldconfig CROSS_COMPILE=$CROSS_COMPILE ARCH=$ARCH bzImage \
        	-j ${JFLAG}
        cp arch/$ARCH/boot/bzImage ${ISODIR}/kernel.gz
    fi   
}

build_busybox () {
    cd ${SOURCEDIR}

    if [ ! -d ${WORKSPACE}/busybox-${BUSYBOX_VERSION} ];
    then
            cp -r busybox-${BUSYBOX_VERSION} ${WORKSPACE}
	    echo "copying busybox patch to workspace"
            cp -r busybox-patch ${WORKSPACE}
            cd  ${WORKSPACE}/busybox-${BUSYBOX_VERSION}
            for patch in $(ls ../busybox-patch | grep '^[000-999]*_.*.patch'); do
                echo "applying patch .... '$patch'."
                patch -p1 < ../busybox-patch/${patch}
            done
    fi

    cd ${WORKSPACE}/busybox-${BUSYBOX_VERSION}

    if [ "$1" == "-c" ]
    then	    
    	make -j$JFLAG ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE clean
    elif [ "$1" == "-b" ]
    then	    
    	cp $LIGHT_OS_BUSYBOX_CONFIG .config
    	make -j$JFLAG ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE oldconfig
    sed -i 's|.*CONFIG_STATIC.*|CONFIG_STATIC=y|' .config
    	make  ARCH=$arm CROSS_COMPILE=$CROSS_COMPILE busybox \
        	-j ${JFLAG}

    	make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE install \
        	-j ${JFLAG}

    	rm -rf ${ROOTFSDIR} && mkdir ${ROOTFSDIR}
    cd _install
    	cp -R . ${ROOTFSDIR}
    	rm  ${ROOTFSDIR}/linuxrc
    fi
}

build_extras () {
    #Build extra soft
    cd ${BASEDIR}/${BUILD_OTHER_DIR}
    if [ "$1" == "-c" ]
    then
    	./build_other_main.sh --clean
    elif [ "$1" == "-b" ]
    then
    	./build_other_main.sh --build	    
    fi	    
}

generate_rootfs () {	
    cd ${ROOTFSDIR}
    rm -f linuxrc

    mkdir dev
    mkdir etc
    mkdir proc
    mkdir src
    mkdir sys
    mkdir var
    mkdir var/log
    mkdir srv
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
    
    cp $BASE_ROOTFS/etc/motd .

    cp $BASE_ROOTFS/etc/hosts .
  
    cp $BASE_ROOTFS/etc/fstab .

    cp $BASE_ROOTFS/etc/mdev.conf .

    cp $BASE_ROOTFS/etc/profile .

    rm -r init.d/*

    install -m ${MODE}     ${BASEDIR}/${BOOT_SCRIPT_DIR}/rc.d/startup              rcS.d/startup
    install -m ${MODE}     ${BASEDIR}/${BOOT_SCRIPT_DIR}/rc.d/shutdown             init.d/shutdown

    chmod +x init.d/*
	
    cp $BASE_ROOTFS/etc/inittab .

    cp $BASE_ROOTFS/etc/group .

    cp $BASE_ROOTFS/etc/passwd .

    cd ${ROOTFSDIR}
   
    cp $BASE_ROOTFS/init .

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
}


generate_image () {

    cd ${SOURCEDIR}/syslinux-${SYSLINUX_VERSION}
    cp bios/core/isolinux.bin ${ISODIR}/
    cp bios/com32/elflink/ldlinux/ldlinux.c32 ${ISODIR}
    cp bios/com32/libutil/libutil.c32 ${ISODIR}
    cp bios/com32/menu/menu.c32 ${ISODIR}
    cd ${ISODIR}
    rm isolinux.cfg && touch isolinux.cfg
    echo 'default kernel.gz initrd=rootfs.gz' >> isolinux.cfg
    echo 'UI menu.c32 ' >> isolinux.cfg
    echo 'PROMPT 0 ' >> isolinux.cfg
    echo >> isolinux.cfg
    echo 'MENU TITLE ACR LINUX 2019.11 /'${SCRIPT_VERSION}': ' >> isolinux.cfg
    echo 'TIMEOUT 60 ' >> isolinux.cfg
    echo 'DEFAULT acr linux ' >> isolinux.cfg
    echo >> isolinux.cfg
    echo 'LABEL acr linux ' >> isolinux.cfg
    echo ' MENU LABEL START ACR LINUX [KERNEL:'${KERNEL_VERSION}']' >> isolinux.cfg
    echo ' KERNEL kernel.gz ' >> isolinux.cfg
    echo ' APPEND initrd=rootfs.gz' >> isolinux.cfg
    echo >> isolinux.cfg
    echo 'LABEL acr_linux_vga ' >> isolinux.cfg
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
}

test_qemu () {
  cd ${BASEDIR}
    if [ -f ${ISO_FILENAME} ];
    then
       qemu-system-x86_64 -m 128M -cdrom ${ISO_FILENAME} -boot d -vga std
    fi
}

clean_files () {
   rm -rf ${SOURCEDIR}
   rm -rf ${ROOTFSDIR}
   rm -rf ${ISODIR}
   rm -rf ${WORKSPACE}
}

init_work_dir()
{
	prepare_dirs
}

clean_work_dir()
{
	clean_files
}

build_all()
{
	build_kernel  -b
	build_busybox -b
	build_extras  -b
}

rebuild_all()
{
	clean_all
	build_all
}

clean_all()
{
	build_kernel  -c
	build_busybox -c
	build_extras  -c
}

wipe_rebuild()
{
	clean_work_dir
	init_work_dir
	rebuild_all
}

build_img ()
{
	build_all
	generate_rootfs
	generate_image
}

help_msg()
{
echo -e "###################################################################################################\n"

echo -e "############################Utility-${SCRIPT_VERSION} to Build x86_64 OS###########################\n"

echo -e "###################################################################################################\n"

echo -e "Help message --help\n"

echo -e "Build and create iso: --build-img\n"

echo -e "Build All: --build-all\n"

echo -e "Rebuild All: --rebuild-all\n"

echo -e "Clean All: --clean-all\n"

echo -e "Wipe and rebuild --wipe-rebuild\n" 

echo -e "Building kernel: --build-kernel --rebuild-kernel --clean-kernel\n"

echo -e "Building busybx: --build-busybox --rebuild-busybox --clean-busybox\n"

echo -e "Building other soft: --build-other --rebuild-other --clean-other\n"

echo -e "Creating root-fs: --create-rootfs\n"

echo -e "Create ISO Image: --create-img\n"

echo -e "Cleaning work dir: --clean-work-dir\n"

echo -e "Test with Qemu --Run-qemu\n"

echo "######################################################################################################"

}

option()
{

if [ -z "$1" ]
then
help_msg
exit 1
fi

if [ "$1" == "--build-all" ]
then	
build_all
fi

if [ "$1" == "--rebuild-all" ]
then
rebuild_all
fi

if [ "$1" == "--clean-all" ]
then
clean_all
fi

if [ "$1" == "--wipe-rebuild" ]
then
wipe_rebuild
fi

if [ "$1" == "--build-kernel" ]
then
build_kernel -b
elif [ "$1" == "--rebuild-kernel" ]
then
build_kernel -c
build_kernel -b
elif [ "$1" == "--clean-kernel" ]
then
build_kernel -c
fi

if [ "$1" == "--build-busybox" ]
then
build_busybox -b
elif [ "$1" == "--rebuild-busybox" ]
then
build_busybox -c
build_busybox -b
elif [ "$1" == "--clean-busybox" ]
then
build_busybox -c
fi

if [ "$1" == "--build-uboot" ]
then
build_uboot -b
elif [ "$1" == "--rebuild-uboot" ]
then
build_uboot -c
build_uboot -b
elif [ "$1" == "--clean-uboot" ]
then
build_uboot -c
fi

if [ "$1" == "--build-other" ]
then
build_extras -b
elif [ "$1" == "--rebuild-other" ]
then
build_extras -c
build_extras -b
elif [ "$1" == "--clean-other" ]
then
build_extras -c
fi

if [ "$1" == "--create-rootfs" ]
then
generate_rootfs
fi

if [ "$1" == "--create-img" ]
then
generate_image
fi

if [ "$1" == "--clean-work-dir" ]
then
clean_work_dir
fi

if [ "$1" == "--Run-qemu" ]
then
test_qemu
fi

if [ "$1" == "--build-img" ]
then
build_img
fi

}

main()
{
int_build_env
init_work_dir
option $1
}

#starting of script
main $1 
