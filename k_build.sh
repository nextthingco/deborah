#!/bin/bash

set -e

if [[ -z "$LINUX_DEPLOY_PRIVATE_KEY" ]]; then
   echo "LINUX_DEPLOY_PRIVATE_KEY is not set -> skip"
else
    eval $(ssh-agent -s)
    ssh-add <(echo "$LINUX_DEPLOY_PRIVATE_KEY")
fi

export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

LINUX_BRANCH=${LINUX_BRANCH:-chip4-4.13.y}
  LINUX_REPO=${LINUX_REPO:-git@github.com:nextthingco/chip4-linux}
LINUX_CONFIG=${LINUX_CONFIG:-chip4_defconfig}
LINUX_SRCDIR="$PWD/linux"

  RTL8723DS_BRANCH=${RTL8723DS_BRANCH:-master}
    RTL8723DS_REPO=${RTL8723DS_REPO:-https://github.com/lwfinger/rtl8723ds}
  RTL8723DS_SRCDIR="$PWD/rtl8723ds"
RTL8723DS_PATCHDIR="$PWD/patches/rtl8723ds"
#git clone -b debian https://github.com/nextthingco/rtl8723ds_bt

export BUILD_NUMBER=${CI_JOB_ID}
export CONCURRENCY_LEVEL=$(( $(nproc) * 2 ))
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

export DEBFULLNAME="Next Thing Co."
export DEBEMAIL="software@nextthing.co"
 
## KERNEL
function linux() {
    git clone --branch ${LINUX_BRANCH} --single-branch --depth 1 ${LINUX_REPO} "${LINUX_SRCDIR}"

    pushd "${LINUX_SRCDIR}"
    git clean -xfd .
    git checkout .
    
   
    export KBUILD_DEBARCH=${ARCH}
    export KDEB_CHANGELOG_DIST=stretch
    export LOCALVERSION=-chip4
    export KDEB_PKGVERSION=$(make kernelversion)-${BUILD_NUMBER}
    
    git config user.email "${DEBEMAIL}"
    git config user.name "${DEBFULLNAME}"
    
    make ${LINUX_CONFIG}

    # remove -gGITREVISION from debian filename
    sed -i "s|CONFIG_LOCALVERSION_AUTO=.*|CONFIG_LOCALVERSION_AUTO=n|" .config    

    make -j${CONCURRENCY_LEVEL} prepare modules_prepare scripts
    make -j${CONCURRENCY_LEVEL} deb-pkg

    popd
}

## WIFI
function wifi() {
    git clone --branch ${RTL8723DS_BRANCH} --single-branch --depth 1 ${RTL8723DS_REPO} "${RTL8723DS_SRCDIR}"

    pushd $RTL8723DS_SRCDIR
    git clean -xfd .
    git checkout .

    git config user.email "${DEBEMAIL}"
    git config user.name "${DEBFULLNAME}"
 
    git am "$RTL8723DS_PATCHDIR"/*

    export BUILDDIR="${RTL8723DS_SRCDIR}/build"
    export RTL_VER=$(cd $RTL8723DS_SRCDIR; dpkg-parsechangelog --show-field Version)

    dpkg-buildpackage -A -uc -us -nc
    sudo dpkg -i ../rtl8723ds-mp-driver-source_${RTL_VER}_all.deb

    mkdir -p $BUILDDIR/usr_src
    export CC=${CROSS_COMPILE}gcc
    export $(dpkg-architecture -a${ARCH})
    export KERNEL_VER=$(cd $LINUX_SRCDIR; make kernelversion)

    cp -a /usr/src/modules/rtl8723ds-mp-driver/* $BUILDDIR
    pushd /usr/src
    sudo tar -zcvf rtl8723ds-mp-driver.tar.gz modules/rtl8723ds-mp-driver
    popd

    m-a -t -u $BUILDDIR \
        -l $KERNEL_VER \
        -k $LINUX_SRCDIR \
        build rtl8723ds-mp-driver-source
    
    mv $BUILDDIR/*.deb ../
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


function createrepo()  {
    export ORIGIN="${ORIGIN:-NTC}"
    export LABEL="${LABEL:-NTC CHIP4}"
    export SUITE="${SUITE:-stable}"
    export CODENAME="${CODENAME:-stretch}"
    export ARCH="${ARCH:-arm64}"
    export COMPONENTS="${COMPONENTS:-main}"
    export DESCRIPTION="${DESCRIPTION:-Kernel and driver packages for NTC CHIP 4}"

    TEMPLATE="${TEMPLATE:-$PWD/distributions.template}"
    REPOPATH="${REPOPATH:-$PWD/repo}"
    DEBSPATH="${DEBSPATH:-$PWD}"

    mkdir -p "${REPOPATH}"/{conf,incoming}

    if [[ -z "${GPG_PRIVATE_KEY}" ]]; then
        echo "No private GPG key given -> SKIP signing"
    else
        gpg --import <(echo "${GPG_PRIVATE_KEY}")
        export SIGNWITH="SignWith: default" 
    fi

    envsubst <"${TEMPLATE}" >"${REPOPATH}/conf/distributions"
    pushd "${REPOPATH}"
    reprepro --ask-passphrase includedeb "${CODENAME}" "${DEBSPATH}"/*.deb
    popd
}

function upload_to_s3()
{
	LOCALPATH=$1
	PATTERN=$2

    [[ -z "${AWS_BUCKET}" || -z "${AWS_REGION}" || -z "${AWS_ACCESS_KEY_ID}" || -z "${AWS_SECRET_ACCESS_KEY}" ]] && echo "S3 upload: missing variables -> SKIP" && return
	aws s3 rm --recursive "${AWS_BUCKET}"
	aws s3 sync --no-progress --acl public-read "${LOCALPATH}" "${AWS_BUCKET}" --exclude "*" --include "${PATTERN}"
}

linux
wifi

createrepo
upload_to_s3 ${REPOPATH} "*"
