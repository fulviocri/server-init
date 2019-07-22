#!/bin/bash
# TRUSTeK Server Init Script
# https://trustek.it

# Am I root?
if [ "x$(id -u)" != 'x0' ]; then
    echo 'Error: this script can only be executed by root'
    exit 1
fi

# Checking wget
if [ ! -e '/usr/bin/wget' ]; then
    yum -y install wget
    check_result $? "Can't install wget"
fi

# Checking tmux
if [ ! -e '/usr/bin/tmux' ]; then
    yum -y install tmux
    check_result $? "Can't install tmux"
fi

# Checking nano
if [ ! -e '/bin/nano' ]; then
    yum -y install nano
    check_result $? "Can't install nano"
fi

yum -y install yum-utils

cp /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0:0
cat /dev/null > /etc/sysconfig/network-scripts/ifcfg-eth0:0
echo DEVICE="eth0:0" > /etc/sysconfig/network-scripts/ifcfg-eth0:0
echo BOOTPROTO=static > /etc/sysconfig/network-scripts/ifcfg-eth0:0
echo IPADDR="94.23.69.56" > /etc/sysconfig/network-scripts/ifcfg-eth0:0
echo NETMASK="255.255.255.255" > /etc/sysconfig/network-scripts/ifcfg-eth0:0
echo ONBOOT=yes > /etc/sysconfig/network-scripts/ifcfg-eth0:0
ifup eth0:0

cp /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0:1
cat /dev/null > /etc/sysconfig/network-scripts/ifcfg-eth0:1
echo DEVICE="eth0:1" > /etc/sysconfig/network-scripts/ifcfg-eth0:1
echo BOOTPROTO=static > /etc/sysconfig/network-scripts/ifcfg-eth0:1
echo IPADDR="94.23.69.125" > /etc/sysconfig/network-scripts/ifcfg-eth0:1
echo NETMASK="255.255.255.255" > /etc/sysconfig/network-scripts/ifcfg-eth0:1
echo ONBOOT=yes > /etc/sysconfig/network-scripts/ifcfg-eth0:1
ifup eth0:1


cp /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0:2
cat /dev/null > /etc/sysconfig/network-scripts/ifcfg-eth0:2
echo DEVICE="eth0:2" > /etc/sysconfig/network-scripts/ifcfg-eth0:2
echo BOOTPROTO=static > /etc/sysconfig/network-scripts/ifcfg-eth0:2
echo IPADDR="94.23.69.171" > /etc/sysconfig/network-scripts/ifcfg-eth0:2
echo NETMASK="255.255.255.255" > /etc/sysconfig/network-scripts/ifcfg-eth0:2
echo ONBOOT=yes > /etc/sysconfig/network-scripts/ifcfg-eth0:2
ifup eth0:2
