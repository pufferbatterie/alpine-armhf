#!/bin/sh
##Build a alpine 3.7-armhf docker image named $TAG
#add main and community mirrors to apk

#http://nl.alpinelinux.org/alpine/MIRRORS.txt
MIRROR=http://nl.alpinelinux.org/alpine/v3.7
REPO=main
ARCH=armhf
TAG=pufferbatterie/armhf-alpine

[ $(id -u) -eq 0 ] || {
  printf >&2 '%s requires root\n' "$0"
  exit 1
}

#create tmp dir
TMP=$(mktemp    -d /tmp/alpine-download-XXXXXXXX)
ROOTFS=$(mktemp -d /tmp/apline-rootfs-XXXXXXXX)

#get APKTOOLS_STATIC_VERSION
APKTOOLS_STATIC_VERSION=$(curl -s ${MIRROR}/${REPO}/${ARCH}/APKINDEX.tar.gz | tar -Oxz | grep '^P:apk-tools-static$' -a -A1 | tail -n1 | cut -d: -f2)

#download APKTOOLS_STATIC to tmp
curl -s ${MIRROR}/${REPO}/${ARCH}/apk-tools-static-${APKTOOLS_STATIC_VERSION}.apk | tar -xz -C ${TMP} sbin/apk.static

#mkbase
${TMP}/sbin/apk.static --repository ${MIRROR}/${REPO} --update-cache --allow-untrusted --root ${ROOTFS} --initdb add alpine-base

#config
echo "${MIRROR}/main"       > ${ROOTFS}/etc/apk/repositories
echo "${MIRROR}/community" >> ${ROOTFS}/etc/apk/repositories

#docker image
IMAGE_ID=$(tar --numeric-owner -C ${ROOTFS} -c . | docker import - ${TAG}:latest)

rm -rf ${TMP}
rm -rf ${ROOTFS}
