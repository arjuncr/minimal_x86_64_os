#!/bin/sh

cd $BASEDIR

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
