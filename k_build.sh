##!/bin/bash

eval $(ssh-agent -s)
ssh-add <(echo "$SSH_PRIVATE_KEY")

#LINUX_DPK_FILE=$PWD/.linux_dpk
#echo "$LINUX_DEPLOY_PRIVATE_KEY" >"${LINUX_DPK_FILE}"
#chmod 0600 "${LINUX_DPK_FILE}"

export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
#export GIT_SSH_COMMAND="ssh -i ${LINUX_DPK_FILE} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

LINUX_BRANCH=${LINUX_BRANCH:-chip4-4.13.y}
  LINUX_REPO=${LINUX_REPO:-git@github.com:nextthingco/chip4-linux}
LINUX_CONFIG=defconfig

#git clone -b debian https://github.com/nextthingco/RTL8723DS
#git clone -b debian https://github.com/nextthingco/rtl8723ds_bt

BUILD_NUMBER=2

## KERNEL
function linux() {
    git clone --branch ${LINUX_BRANCH} --single-branch --depth 1 ${LINUX_REPO} linux
    pushd linux
    git clean -xfd .
    git checkout .
    
    export DEBFULLNAME="Next Thing Co."
    export DEBEMAIL="software@nextthing.co"
    export CONCURRENCY_LEVEL=$(( $(nproc) * 2 ))
    
    export ARCH=arm64
    export CROSS_COMPILE=aarch64-linux-gnu-
    export KBUILD_DEBARCH=${ARCH}
    export KDEB_CHANGELOG_DIST=stretch
    export LOCALVERSION=-chip4
    export KDEB_PKGVERSION=$(make kernelversion)-${BUILD_NUMBER}
    
    git config user.email "${DEBEMAIL}"
    git config user.name "${DEBFULLNAME}"
    
    make ${LINUX_CONFIG}
    
    make -j${CONCURRENCY_LEVEL} prepare modules_prepare scripts
    make -j${CONCURRENCY_LEVEL} deb-pkg

    popd
}

## WIFI
function wifi() {
    export LINUX_SRCDIR="$(pwd)/linux"
    export RTL8723DS_SRCDIR="$(pwd)/RTL8723DS"
    export BUILDDIR=$RTL8723DS_SRCDIR/build
    export CONCURRENCY_LEVEL=$(( $(nproc) * 2 ))
    export RTL_VER=$(cd $RTL8723DS_SRCDIR; dpkg-parsechangelog --show-field Version)
    
    pushd $RTL8723DS_SRCDIR
    git clean -xfd .
    git checkout .
    
    dpkg-buildpackage -A -uc -us -nc
    sudo dpkg -i ../rtl8723ds-mp-driver-source_${RTL_VER}_all.deb
    
    mkdir -p $BUILDDIR/usr_src
    export CC=arm-linux-gnueabihf-gcc
    export $(dpkg-architecture -aarmhf)
    export CROSS_COMPILE=arm-linux-gnueabihf-
    export KERNEL_VER=$(cd $LINUX_SRCDIR; make kernelversion)
    
    cp -a /usr/src/modules/rtl8723ds-mp-driver/* $BUILDDIR
    pushd /usr/src
    sudo tar -zcvf rtl8723ds-mp-driver.tar.gz modules/rtl8723ds-mp-driver
    popd

    m-a -t -u $BUILDDIR \
        -l $KERNEL_VER \
        -k $LINUX_SRCDIR \
        build rtl8723ds-mp-driver-source
    
    
    pushd $BUILDDIR/*.deb ../
    
    popd
}

## BT
function bluetooth() {
    pushd rtl8723ds_bt
    git clean -xfd .
    git checkout .
    
    dpkg-buildpackage -uc -us -nc
    
    popd
}

linux
