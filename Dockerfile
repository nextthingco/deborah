FROM debian:stretch

RUN apt -y update && apt -y upgrade && apt -y install \
debootstrap \
qemu-user-static \
cpio \
u-boot-tools \
crossbuild-essential-arm64 dpkg-dev dh-make dh-systemd dkms module-assistant bc \
git vim 

