#!/bin/bash

BASEDIR=$(dirname "$0")

source $BASEDIR/proxy.conf

MACHINE_ARCH=`uname -m`

WSTRINGS=`which strings`
WAPT=`which apt-get`
WYUM=`which yum`

if [ -z "$WSTRINGS" ]; then

if [ ! -z "$WAPT" ]; then

apt-get -y install binutils

fi

if [ ! -z "$WYUM" ]; then

yum -y install binutils

fi

fi

INIT_SYSTEM=`strings /sbin/init | awk 'match($0, /(upstart|systemd|sysvinit)/) { print tolower(substr($0, RSTART, RLENGTH));exit; }'`

PROXY_PID=`pgrep -f proxy.*socks`

if [ ! -z $PROXY_PID ]; then

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

ls -la $TMP_IN_DIR/1tmp-proxy-installation-directory/

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

if [ ! -z "$SYSV1" ]; then

update-rc.d -f proxy enable

fi

if [ ! -z "$SYSV2" ]; then

chkconfig --add proxy
chkconfig --level 2345 proxy on

fi

if [ -z "$SYSV1" ] && [ -z "$SYSV2" ]; then

echo ""
echo "Please manually enable auto-startup in your linux distribution for /etc/init.d/proxy script"
echo ""

fi

echo "Starting proxy..."

/etc/init.d/proxy restart

fi

if [ "$INIT_SYSTEM" = "systemd" ]; then

echo "Installing Systemd Unit /lib/systemd/system/proxy.service"

cp proxy-systemd /lib/systemd/system/proxy.service
systemctl enable proxy

echo "Starting proxy..."

systemctl restart proxy

fi

if [ "$INIT_SYSTEM" = "upstart" ]; then

echo "Installing Upstart Script /etc/init/proxy.conf"

cp proxy-upstart /etc/init/proxy.conf

#echo "Starting proxy..."

#start proxy

cp proxy-sysv /etc/init.d/proxy

SYSV1=`which update-rc.d`
SYSV2=`which chkconfig`

if [ ! -z "$SYSV1" ]; then

update-rc.d -f proxy enable

fi

if [ ! -z "$SYSV2" ]; then

chkconfig --add proxy
chkconfig --level 2345 proxy on

fi

if [ -z "$SYSV1" ] && [ -z "$SYSV2" ]; then

echo ""
echo "Please manually enable auto-startup in your linux distribution for /etc/init.d/proxy script"
echo ""

fi

echo "Starting proxy..."

/etc/init.d/proxy restart

fi

rm -rf $TMP_IN_DIR/1tmp-proxy-installation-directory/

echo ""
echo "TCP Port Socks5: $SPORT"
echo "Username: $SUSER"
echo "Password: $SPASS"
echo ""
echo "Enjoy!"

#END
