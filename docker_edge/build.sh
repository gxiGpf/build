#!/bin/ash

set -e

ROOTDIR="/alpine"

apk --arch x86_64 -X http://dl-cdn.alpinelinux.org/alpine/edge/main/ -U --allow-untrusted --root ${ROOTDIR} --initdb add alpine-base openssh ethtool net-tools mbedtls ruby fuse3 sshpass rsync curl 
apk --arch x86_64 -X http://dl-cdn.alpinelinux.org/alpine/edge/community -U --allow-untrusted --root ${ROOTDIR} --initdb add fuse
apk --arch x86_64 -X http://dl-cdn.alpinelinux.org/alpine/edge/testing -U --allow-untrusted --root ${ROOTDIR} --initdb add dislocker epoch
cp /etc/apk/repositories $ROOTDIR/etc/apk/

# boot
for d in hostname procfs sysfs urandom hwdrivers; do
  ln -vs "/etc/init.d/${d}" $ROOTDIR/etc/runlevels/boot/
done

# default
for d in sshd; do
  ln -vs "/etc/init.d/${d}" $ROOTDIR/etc/runlevels/default/
done

# local
ln -vs /etc/init.d/local $ROOTDIR/etc/runlevels/default/

cp -v /init $ROOTDIR/
cp -v /dhcp.start $ROOTDIR/etc/local.d/

echo initrd >> $ROOTDIR/etc/hostname

echo >> $ROOTDIR/etc/ssh/sshd_config
echo PermitRootLogin yes >> $ROOTDIR/etc/ssh/sshd_config
echo PermitEmptyPasswords yes >> "$ROOTDIR"/etc/ssh/sshd_config
