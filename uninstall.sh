#!/bin/bash

INIT_SYSTEM=`strings /sbin/init | awk 'match($0, /(upstart|systemd|sysvinit|busybox)/) { print tolower(substr($0, RSTART, RLENGTH));exit; }'`

PROXY_PID=`pgrep -f proxy.*socks`

if [ ! -z "$PROXY_PID" ]; then

kill -9 $PROXY_PID;

fi

test -d /etc/proxy && rm -rf /etc/proxy || exit 1

CHECK_USER=`cat /etc/passwd |grep 'proxy:' |grep -v 'systemd'`

echo "Uninstalling:"
echo ""

if [ ! -z "$CHECK_USER" ]; then

echo "Deleting proxy user from system"

userdel proxy

fi

CHECK_GROUP=`cat /etc/group |grep 'proxy:' |grep -v 'systemd'`

if [ ! -z "$CHECK_GROUP" ]; then

echo "Deleting proxy group from system"

groupdel proxy

fi

echo "Deleting proxy binary /usr/bin/proxy"

test -f /usr/bin/proxy && rm -f /usr/bin/proxy

if [ "$INIT_SYSTEM" = "sysvinit" ]; then

echo "Removing SysV Init script /etc/init.d/proxy"

SYSV1=`which update-rc.d`
SYSV2=`which chkconfig`
SYSV3=`which rc-update`

if [ ! -z "$SYSV1" ]; then

update-rc.d -f proxy disable

fi

if [ ! -z "$SYSV2" ]; then

chkconfig --del proxy

fi

if [ ! -z "$SYSV3" ]; then

rc-update del proxy

fi

test -f /etc/init.d/proxy && rm -f /etc/init.d/proxy

fi

if [ "$INIT_SYSTEM" = "systemd" ]; then

echo "Removing Systemd Unit /lib/systemd/system/proxy.service"

systemctl disable proxy

if [ ! -d /lib/systemd/system ]; then

test -f /usr/lib/systemd/system/proxy.service && rm -f /usr/lib/systemd/system/proxy.service

else

test -f /lib/systemd/system/proxy.service && rm -f /lib/systemd/system/proxy.service

fi

fi

if [ "$INIT_SYSTEM" = "upstart" ]; then

echo "Removing Upstart/SysV Scripts /etc/init.d/proxy ; /etc/init/proxy.conf"

test -f /etc/init/proxy.conf && rm -f /etc/init/proxy.conf

SYSV1=`which update-rc.d`
SYSV2=`which chkconfig`
SYSV3=`which rc-update`

if [ ! -z "$SYSV1" ]; then

update-rc.d -f proxy disable

fi

if [ ! -z "$SYSV2" ]; then

chkconfig --del proxy

fi

if [ ! -z "$SYSV3" ]; then

rc-update del proxy

fi

test -f /etc/init.d/proxy && rm -f /etc/init.d/proxy

fi

if [ "$INIT_SYSTEM" = "busybox" ]; then

echo "Removing Busybox Script /etc/init.d/proxy"

rc-update del proxy

test -f /etc/init.d/proxy && rm -f /etc/init.d/proxy

fi

echo ""
echo "Uninstall telegram-proxy completed"

#END
