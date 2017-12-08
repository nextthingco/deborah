FROM debian:stretch

RUN  \
dpkg --add-architecture armhf && \
dpkg --add-architecture arm64 && \
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
libstdc++6:arm64 libgcc1:arm64 zlib1g:arm64 libncurses5:arm64 \
&& \
pip install awscli --upgrade
