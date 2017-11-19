#!/bin/bash

source connman-android-env.sh

${NDK}/build/tools/make-standalone-toolchain.sh --toolchain=${TOOLCHAIN}eabi-4.9 --platform=android-24 --install-dir=`pwd`/android-toolchain

