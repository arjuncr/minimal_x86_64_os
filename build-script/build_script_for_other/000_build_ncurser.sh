# @author ARJUN C R (arjuncr00@gmail.com)
#
# web site https://www.acrlinux.com
#
#!/bin/bash

cd $BASEDIR

cd ${SOURCEDIR}

    if [ ! -d ${WORKSPACE}/ncurses-${NCURSES_VERSION} ];
    then
	    echo "copying ncurses-${NCURSES_VERSION} ${WORKSPACE}"
            cp -r ncurses-${NCURSES_VERSION} ${WORKSPACE}
    fi

cd ${WORKSPACE}/ncurses-${NCURSES_VERSION}

    if [ "$1" == "--clean" ] 
    then
        make -j ${JFLAG} clean
    elif [ "$1" == "--build" ]
    then	    
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

    fi
