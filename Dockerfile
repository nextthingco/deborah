FROM debian:stretch

RUN apt -y update && apt -y upgrade && apt -y install \
debootstrap \
qemu-user-static \
cpio \
u-boot-tools \
dpkg-dev dh-make dh-systemd dkms module-assistant bc reprepro \
crossbuild-essential-arm64 \
crossbuild-essential-armhf \
git vim python-pip \
&& \
pip install awscli --upgrade

