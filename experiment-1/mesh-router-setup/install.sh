#!/bin/sh
opkg update

# 0. Workaround for missing hostname command
## https://github.com/openwrt/openwrt/issues/11765
echo "cat /proc/sys/kernel/hostname" > /sbin/hostname
chmod 755 /sbin/hostname

# 1. OVS - package and ports
opkg install openvswitch

# Workaround for buggy OpenVSwtich startup scripts
cp rc.local /etc/
chmod 755 /etc/rc.local
/etc/rc.local

## Create iot bridge
ovs-vsctl add-br iot

## Ports for VLAN-interfaces created by hostapd
echo "Added VLANs 20 to 40 to OVS bridge, ignoring errors resulting from non-existing devices. This can take a while"
index=20
while [ $index -le 41 ]; do
   /usr/bin/ovs-vsctl add-port iot iot_$index 2> /dev/null
   index=$(( index + 1 ))
done

echo "Creating a lan-port at the OVS-bridge that can be utilized to distribute lan-packets along the mesh"
ovs-vsctl add-port iot iotupl -- set Interface iotupl type=internal

## Add Port eth2 (wired IoT-Port to the bridge
ovs-vsctl add-port iot eth2

## Create OpenWRT network configuration for the IoT bridge
uci import -m < network_iot_if.uci
uci commit network

