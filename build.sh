#!/bin/sh

echo -e "*****************************"
echo -e "**                         **"
echo -e "** Building NIKA...        **"
echo -e "**                         **"
echo -e "*****************************"

export LLVM=1

# KernelSU-Next
curl -LSs "https://raw.githubusercontent.com/rifsxd/KernelSU-Next/next/kernel/setup.sh" | bash -s v1.0.2-R14

# Clang
echo "Using Clang18"
git clone -b master https://gitlab.com/kei-space/clang/r522817.git --depth=1 clang

# Some general variables
KERNELNAME="MODEL:NIKA-by-Debarpan102"
ARCH="arm64"
SUBARCH="arm64"
DEFCONFIG=vendor/lahaina-qgki_defconfig
COMPILER=clang
LINKER=""
KERNEL_DIR=""
COMPILERDIR="${KERNEL_DIR}/clang"

# Export shits
export KBUILD_BUILD_USER=Debarpan102
export KBUILD_BUILD_HOST=Ubuntu

# Select LTO variant ( Full LTO by default )
DISABLE_LTO=0
THIN_LTO=1


# Create Logs
exec 2> >(tee -a out/error.log >&2)

# Speed up build process
MAKE="./makeparallel"

# Basic build function
BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

Build () {
PATH="${COMPILERDIR}/bin:${PATH}" \
make -j$(nproc --all) O=out \
ARCH=${ARCH} \
CC=${COMPILER} \
CROSS_COMPILE=${COMPILERDIR}/bin/aarch64-linux-gnu- \
CROSS_COMPILE_ARM32=${COMPILERDIR}/bin/arm-linux-gnueabi- \
LD_LIBRARY_PATH=${COMPILERDIR}/lib
}

Build_lld () {
PATH="${COMPILERDIR}/bin:${PATH}" \
make -j$(nproc --all) O=out \
ARCH=${ARCH} \
CC=${COMPILER} \
CROSS_COMPILE=${COMPILERDIR}/bin/aarch64-linux-gnu- \
CROSS_COMPILE_ARM32=${COMPILERDIR}/bin/arm-linux-gnueabi- \
LD=ld.${LINKER} \
AR=llvm-ar \
NM=llvm-nm \
OBJCOPY=llvm-objcopy \
OBJDUMP=llvm-objdump \
STRIP=llvm-strip \
ld-name=${LINKER} \
KBUILD_COMPILER_STRING="Prelude Clang"
}

# Make defconfig

make O=out ARCH=${ARCH} ${DEFCONFIG}
if [ $? -ne 0 ]
then
    echo "Build failed"
else
    echo "Made ${DEFCONFIG}"
fi

# Build starts here
if [ -z ${LINKER} ]
then
    Build
else
    Build_lld
fi

if [ $? -ne 0 ]
then
    echo "Build failed"
else
    echo "Build succesful"
fi


Build
END=$(date +"%s")

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
