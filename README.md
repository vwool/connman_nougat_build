This project aims to get you connman and dbus compiled for your
Android Nougat ARM or ARM64 platform.

Basically you just need to have all the Android tools installed, as
well as Android NDK, and the Linux autoconf/automake and friends. If
you have all these, building connman should be a matter of adjusting
the values in connman-android-env.sh, then running:
$ ./toolchain.sh
$ ./build.sh

and then you'll get the result in install/ folder.

If you have your Android device connected, you can then do, for
instance, adb sync to push the files onto it:

$ ANDROID\_PRODUCT\_OUT=./install adb sync

Then, on target, do the following:

\# insmod /system/lib/modules/wlan.ko
\# rm /data/misc/dbus/pid
\# dbus-daemon --config-file=/system/etc/dbus/system.conf
