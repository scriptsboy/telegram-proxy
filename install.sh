#!/bin/bash

BASEDIR=$(dirname "$0")

source $BASEDIR/proxy.conf

MACHINE_ARCH=`uname -m`

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
cp $BASEDIR/* $TMP_IN_DIR/1tmp-proxy-installation-directory/

echo "Unpacking proxy server"

if [ "$MACHINE_ARCH" = "x86_64" ]; then

cp -r $BASEDIR/proxy-binaries/proxy-linux-amd64.tar.gz $TMP_IN_DIR/1tmp-proxy-installation-directory/

elif [ "$MACHINE_ARCH" = "i386" ] || [ "$MACHINE_ARCH" = "i486" ] || [ "$MACHINE_ARCH" = "i586" ] || [ "$MACHINE_ARCH" = "i686" ] ; then

cp -r $BASEDIR/proxy-binaries/proxy-linux-386.tar.gz $TMP_IN_DIR/1tmp-proxy-installation-directory/

else

echo "Unsupported machine architecture: $MACHINE_ARCH"

exit 1

fi

cd $TMP_IN_DIR/1tmp-proxy-installation-directory/

if [ "$MACHINE_ARCH" = "x86_64" ]; then

tar xzf proxy-linux-amd64.tar.gz

elif [ "$MACHINE_ARCH" = "i386" ] || [ "$MACHINE_ARCH" = "i486" ] || [ "$MACHINE_ARCH" = "i586" ] || [ "$MACHINE_ARCH" = "i686" ] ; then

tar xzf proxy-linux-386.tar.gz

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
chmod a+x /usr/bin/proxy

echo "Installing SysV init script /etc/init.d/proxy"

cp proxy-init /etc/init.d/proxy

update-rc.d -f proxy enable
update-rc.d -f proxy defaults

echo "Starting proxy..."

/etc/init.d/proxy restart

rm -rf $TMP_IN_DIR/1tmp-proxy-installation-directory/

echo ""
echo "TCP Port Socks5: $SPORT"
echo "Username: $SUSER"
echo "Password: $SPASS"
echo ""
echo "Enjoy!"

#END
