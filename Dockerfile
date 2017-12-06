FROM debian:stretch

RUN  \
dpkg --add-architecture armhf && \
dpkg --add-architecture aarch64 && \
apt -y update && apt -y upgrade && apt -y install \
debootstrap \
qemu-user-static \
cpio \
u-boot-tools \
dpkg-dev dh-make dh-systemd dkms module-assistant bc reprepro \
crossbuild-essential-arm64 \
crossbuild-essential-armhf \
git vim python-pip \
libstdc++6:armhf libgcc1:armhf zlib1g:armhf libncurses5:armhf \
libstdc++6:aarch64 libgcc1:aarch64 zlib1g:aarch64 libncurses5:aarch64 \
&& \
pip install awscli --upgrade
