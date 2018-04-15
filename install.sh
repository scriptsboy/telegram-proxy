#!/bin/bash

BASEDIR=$(dirname "$0")

source $BASEDIR/proxy.conf

MACHINE_ARCH=`uname -m`

WSTRINGS=`which strings`
WAPT=`which apt-get`
WYUM=`which yum`
WZYP=`which zypper`
WEMR=`which emerge`
WPAC=`which pacman`
WAPK=`which apk`

if [ -z "$WSTRINGS" ]; then

if [ ! -z "$WAPT" ]; then

apt-get update
apt-get -y install binutils

fi

if [ ! -z "$WYUM" ]; then

yum -y install binutils

fi

if [ ! -z "$WZYP" ]; then

zypper -n install binutils

fi

if [ ! -z "$WEMR" ]; then

emerge binutils

fi

if [ ! -z "$WPAC" ]; then

pacman-key --populate archlinux
pacman --noconfirm -y -S binutils

fi

if [ ! -z "$WAPK" ]; then

apk update
apk add bash
apk add binutils
apk add shadow

fi

fi

INIT_SYSTEM=`strings /sbin/init | awk 'match($0, /(upstart|systemd|sysvinit|busybox)/) { print tolower(substr($0, RSTART, RLENGTH));exit; }'`

PROXY_PID=`pgrep -f proxy.*socks`

if [ ! -z "$PROXY_PID" ]; then

kill -9 $PROXY_PID;

fi

mkdir -p /etc/proxy || exit 1

if [ -w /tmp ] ; then

TMP_IN_DIR="/tmp"

else

TMP_IN_DIR="/root"

if [ ! -w /root ] ; then

echo ""
echo "Not enough rigths for write to /tmp or /root"

exit 1

fi

fi

mkdir -p $TMP_IN_DIR/1tmp-proxy-installation-directory/ || exit 1
cp -R $BASEDIR/* $TMP_IN_DIR/1tmp-proxy-installation-directory/

echo "Unpacking proxy server"

cd $TMP_IN_DIR/1tmp-proxy-installation-directory/

if [ "$MACHINE_ARCH" = "x86_64" ]; then

tar xzf proxy-binaries/proxy-linux-amd64.tar.gz

elif [ "$MACHINE_ARCH" = "i386" ] || [ "$MACHINE_ARCH" = "i486" ] || [ "$MACHINE_ARCH" = "i586" ] || [ "$MACHINE_ARCH" = "i686" ] ; then

tar xzf proxy-binaries/proxy-linux-386.tar.gz

else

echo "Unsupported machine architecture: $MACHINE_ARCH"

exit 1

fi

CHECK_USER=`cat /etc/passwd |grep 'proxy:' |grep -v 'systemd'`
CHECK_GROUP=`cat /etc/group |grep 'proxy:' |grep -v 'systemd'`

echo "Installing:"
echo ""

if [ -z "$CHECK_GROUP" ]; then

echo "Adding proxy group to system"

groupadd proxy

fi

if [ -z "$CHECK_USER" ]; then

echo "Adding proxy user to system"

useradd proxy -g proxy

fi

echo "Copying configuration to /etc/proxy/proxy.conf file"

cp proxy.conf /etc/proxy/

if [ ! -e proxy ]; then

echo ""
echo "File does not exists, may be corrupt archive"
echo ""

fi

echo "Copying proxy binary to /usr/bin/proxy"

cp proxy /usr/bin/
chown root.root /usr/bin/proxy
chmod a+x /usr/bin/proxy

if [ "$INIT_SYSTEM" = "sysvinit" ]; then

echo "Installing SysV Init script /etc/init.d/proxy"

cp proxy-sysv /etc/init.d/proxy

SYSV1=`which update-rc.d`
SYSV2=`which chkconfig`
SYSV3=`which rc-update`

if [ ! -z "$SYSV1" ]; then

update-rc.d -f proxy defaults
update-rc.d -f proxy enable

fi

if [ ! -z "$SYSV2" ]; then

chkconfig --add proxy
chkconfig --level 2345 proxy on

fi

if [ ! -z "$SYSV3" ]; then

rc-update add proxy

fi

echo "Starting proxy..."

/etc/init.d/proxy restart

fi

if [ "$INIT_SYSTEM" = "systemd" ]; then

echo "Installing Systemd Unit /lib/systemd/system/proxy.service"

if [ ! -d /lib/systemd/system ]; then

cp proxy-systemd /usr/lib/systemd/system/proxy.service

else

cp proxy-systemd /lib/systemd/system/proxy.service

fi

systemctl enable proxy

echo "Starting proxy..."

systemctl restart proxy

fi

if [ "$INIT_SYSTEM" = "upstart" ]; then

echo "Installing Upstart/SysV Scripts /etc/init.d/proxy ; /etc/init/proxy.conf"

cp proxy-upstart /etc/init/proxy.conf

#echo "Starting proxy..."

#start proxy

cp proxy-sysv /etc/init.d/proxy

SYSV1=`which update-rc.d`
SYSV2=`which chkconfig`
SYSV3=`which rc-update`

if [ ! -z "$SYSV1" ]; then

update-rc.d -f proxy defaults
update-rc.d -f proxy enable

fi

if [ ! -z "$SYSV2" ]; then

chkconfig --add proxy
chkconfig --level 2345 proxy on

fi

if [ ! -z "$SYSV3" ]; then

rc-update add proxy

fi

echo "Starting proxy..."

/etc/init.d/proxy restart

fi

if [ "$INIT_SYSTEM" = "busybox" ]; then

echo "Installing Busybox Script /etc/init.d/proxy"

cp proxy-busybox /etc/init.d/proxy

rc-update add proxy

echo "Starting proxy..."

/etc/init.d/proxy restart

fi

rm -rf $TMP_IN_DIR/1tmp-proxy-installation-directory/

IPS=($(hostname -I 2>/dev/null))

echo ""
echo "TCP Port Socks5: $SPORT"
echo "Username: $SUSER"
echo "Password: $SPASS"
echo ""
echo "Socks5 Proxy IPs:"
echo ""

if [ ! -z "$IPS" ]; then

for LIP in $( IFS=$'\n'; echo "${IPS[*]}" )
do

echo "IP: $LIP:$SPORT"

done

echo ""

for LIP in $( IFS=$'\n'; echo "${IPS[*]}" )
do

echo "Telegram Link: tg://socks?server=$LIP&port=$SPORT&user=$SUSER&pass=$SPASS"

done

else

IPS=$(ip -o addr | awk '!/^[0-9]*: ?lo|link\/ether/ {gsub("/", " "); print $4}')

for LIP in $( IFS=$'\n'; echo "${IPS[*]}" )
do

echo "IP: $LIP:$SPORT"

done

echo ""

for LIP in $( IFS=$'\n'; echo "${IPS[*]}" )
do

echo "Telegram Link: tg://socks?server=$LIP&port=$SPORT&user=$SUSER&pass=$SPASS"

done

fi

echo ""
echo "Enjoy!"

#END
