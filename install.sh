#!/bin/bash

BASEDIR=$(dirname "$0")

source $BASEDIR/proxy.conf

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
echo "Not enough write rigths to /tmp or /root"

exit 1

fi

fi

mkdir -p $TMP_IN_DIR/1tmp-proxy-installation-directory/ || exit 1
cp $BASEDIR/* $TMP_IN_DIR/1tmp-proxy-installation-directory/

cd $TMP_IN_DIR/1tmp-proxy-installation-directory/

CHECK_USER=`cat /etc/passwd |grep 'proxy:' |grep -v 'systemd'`
CHECK_GROUP=`cat /etc/group |grep 'proxy:' |grep -v 'systemd'`

if [ -z "$CHECK_GROUP" ]; then

echo ""
echo "Adding proxy group to system"

groupadd proxy

fi

if [ -z "$CHECK_USER" ]; then

echo "Adding proxy user to system"

useradd proxy -g proxy

fi

echo "Copying configuration to /etc/proxy/proxy.conf file"

cp proxy.conf /etc/proxy/

echo "Downloading proxy"

if [ -e proxy-linux-amd64.tar.gz ]; then

rm -f proxy-linux-amd64.tar.gz

fi

wget https://github.com/snail007/goproxy/releases/download/v4.6/proxy-linux-amd64.tar.gz 1>/dev/null 2>/dev/null

if [ ! -e proxy-linux-amd64.tar.gz ]; then

echo ""
echo "File is not downloaded"
echo ""

fi

echo "Unpacking proxy-linux-amd64.tar.gz"

tar xzf proxy-linux-amd64.tar.gz

if [ ! -e proxy ]; then

echo ""
echo "File does not exists, may be corrupt archive"
echo ""

fi

echo "Copying proxy binary to /usr/bin/proxy"

cp proxy /usr/bin/
chmod a+x /usr/bin/proxy

echo "Installing SysV init scipt /etc/init.d/proxy"

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
