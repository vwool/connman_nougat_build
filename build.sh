#!/bin/bash

source connman-android-env.sh

if [ -n "$ANDROID_PRODUCT_OUT" ]; then
	LIBXTABLES_A=$ANDROID_PRODUCT_OUT/obj/STATIC_LIBRARIES/libxtables_intermediates/libxtables.a
	LIBEXPAT_SO=$ANDROID_PRODUCT_OUT/obj/SHARED_LIBRARIES/libexpat_intermediates/PACKED/libexpat.so
else
	echo "\$ANDROID_PRODUCT_OUT not set, will use default libraries"
	LIBXTABLES_A=`pwd`/files/libxtables.a
	LIBEXPAT_SO=`pwd`/files/libexpat.so
fi

export LIBEXPAT_SO
export LIBXTABLES_A

EXTRA_MAKE_PARAMS="-j10"

#libiconv
(
wget https://ftp.gnu.org/gnu/libiconv/libiconv-1.14.tar.gz || exit 1
tar xzf libiconv-1.14.tar.gz || exit 1
cd libiconv-1.14
patch -p1 < ../patches/libiconv.patch
./configure --host=${OLD_TARGET} --prefix=${PREFIX} --enable-shared --disable-static || exit 1
make $EXTRA_MAKE_PARAMS && make install
)

#libffi
(
wget ftp://sourceware.org/pub/libffi/libffi-3.2.1.tar.gz || exit 1
tar xzf libffi-3.2.1.tar.gz || exit 1
cd libffi-3.2.1
./configure --host=${OLD_TARGET} --prefix=${PREFIX} || exit 1
make $EXTRA_MAKE_PARAMS && make install
)

# readline
(
git clone https://github.com/marcv81/readline || exit 1
cd readline
patch -p1 < ../patches/readline.patch
./configure --host=${OLD_TARGET} --prefix=${PREFIX} --enable-shared --disable-static || exit 1
make $EXTRA_MAKE_PARAMS && make install
)

# pre-dbus
(
( cd ${PREFIX} && patch -p1 < $OLDPWD/patches/pre-dbus.patch )
( cp $LIBEXPAT_SO ${PREFIX}/lib/ )
)

# dbus
(
wget https://dbus.freedesktop.org/releases/dbus/dbus-1.6.14.tar.gz || exit 1
tar xzf dbus-1.6.14.tar.gz || exit 1
cd dbus-1.6.14
patch -p1 < ../patches/dbus.patch
./configure --host=${OLD_TARGET} --prefix=${PREFIX} --with-sysroot=${SYSROOT} --disable-Werror --disable-rt --with-systemdsystemunitdir=/tmp --with-system-socket=/data/misc/dbus/system_bus_socket --with-session-socket-dir=/data/misc/dbus --with-system-pid-file=/data/misc/dbus/pid --with-dbus-user=root || exit 1
make $EXTRA_MAKE_PARAMS && make install
)

# gettext
(
wget https://ftp.gnu.org/gnu/gettext/gettext-0.18.3.tar.gz || exit 1
tar xzf gettext-0.18.3.tar.gz || exit 1
cd gettext-0.18.3
patch -p1 < ../patches/gettext.patch
./configure --host=${OLD_TARGET} --prefix=${PREFIX} --disable-rpath --disable-libasprintf --disable-java --disable-native-java --disable-openmp --disable-curses || exit 1
make $EXTRA_MAKE_PARAMS && make install
)

# glib
(
cp files/libintl.h ${PREFIX}/include/
wget https://ftp.gnome.org/pub/gnome/sources/glib/2.48/glib-2.48.1.tar.xz || exit 1
tar xJf glib-2.48.1.tar.xz || exit 1
cd glib-2.48.1
patch -p1 < ../patches/glib.patch
./configure --host=${ANDROID_TARGET} --prefix=${PREFIX} --with-sysroot=${SYSROOT} --disable-dependency-tracking --cache-file=android.cache --enable-included-printf --enable-static --disable-shared --with-pcre=no || exit 1
make $EXTRA_MAKE_PARAMS && make install
)

# termcap
(
git clone https://github.com/marcv81/termcap || exit 1
cd termcap
git am ../patches/termcap.patch.d/* || exit 1
./configure --host=${ANDROID_TARGET} --prefix=${PREFIX} --with-sysroot=${SYSROOT} || exit 1
make $EXTRA_MAKE_PARAMS && make install
)

# connman
(
cp files/xtables.h ${PREFIX}/include/
cp files/res*.h ${PREFIX}/include/
cp files/xtables.pc ${PREFIX}/lib/pkgconfig/
cp $LIBXTABLES_A ${PREFIX}/lib/
git clone git://git.kernel.org/pub/scm/network/connman/connman.git || exit 1
cd connman
git checkout c4df81f8b9d01c2f0e85e82c73177e91958399db
git am ../patches/connman.patch.d/* || exit 1
./bootstrap
./configure --host=${ANDROID_TARGET} --prefix=${PREFIX} --disable-bluetooth --disable-loopback --disable-ethernet --disable-gadget --disable-ofono --disable-dundee --disable-pacrunner --disable-neard --disable-wispr --disable-tools --enable-pie || exit 1
make $EXTRA_MAKE_PARAMS
)

INSTALL_LIBS="\
	lib/libiconv.so.2 \
	lib/libdbus-1.so.3 \
	lib/libintl.so.8 \
	lib/libreadline.so.6"

INSTALL_PROGRAMS="\
	bin/dbus-daemon \
	bin/dbus-cleanup-sockets \
	bin/dbus-launch \
	bin/dbus-monitor \
	bin/dbus-send"

INSTALL_CONNMAND="\
	connman/client/connmanctl \
	connman/src/connmand"

LIBDIR="/system/lib"
if [ "${ANDROID_ARCH}" = "arm64" ]; then
	LIBDIR="/system/lib64"
fi

cp -r files/trg install
mkdir -p install/$LIBDIR
mkdir -p install/system/bin

for f in $INSTALL_LIBS; do
	cp ${PREFIX}/$f install/$LIBDIR || exit 1
done

for f in $INSTALL_PROGRAMS; do
	cp ${PREFIX}/$f install/system/bin || exit 1
done

for f in $INSTALL_CONNMAND; do
	cp $f install/system/bin || exit 1
done

