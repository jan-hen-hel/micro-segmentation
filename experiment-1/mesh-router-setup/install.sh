#!/bin/sh
opkg update

echo "0. Workaround for missing hostname command"
## https://github.com/openwrt/openwrt/issues/11765
echo "cat /proc/sys/kernel/hostname" > /sbin/hostname
chmod 755 /sbin/hostname

echo "1. OVS - package and ports"
opkg install openvswitch

echo "Workaround for buggy OpenVSwtich startup scripts"
cp rc.local /etc/
chmod 755 /etc/rc.local
/etc/rc.local

echo "Create iot bridge - setting failmode to secure to avoid accidental briding"
ovs-vsctl add-br iot

ovs-vsctl set-fail-mode iot secure

## Ports for VLAN-interfaces created by hostapd
echo "Added VLANs 20 to 40 to OVS bridge, ignoring errors resulting from non-existing devices. This can take a while"
index=20
while [ $index -le 41 ]; do
   /usr/bin/ovs-vsctl add-port iot iot_$index -- set Interface iot_$index  ofport=$index
   index=$(( index + 1 ))
done

echo "Creating a lan-port at the OVS-bridge that can be utilized to distribute lan-packets along the mesh"
ovs-vsctl add-port iot iotupl -- set Interface iotupl type=internal

## Add Port eth2 (wired IoT-Port to the bridge
echo "Adding eth2 (wired IoT-Port) to OVS bridge"
ovs-vsctl add-port iot eth2

## Create OpenWRT network configuration for the IoT bridge
echo "Defining UCI network configuration for OVS bridge-ports"
uci -m import network < network_iot_if.uci
uci add_List network.@device[0].ports='iotupl'
uci commit network

echo "Setting up WLAN-AP for iot network"
uci -m import wireless < iot_wireless.uci
uci commit wireless

echo "Creating Firewall-Zone for iot-Network"
echo "Setting up WLAN-AP for iot network"
uci -m import firewall < firewall.uci
uci commit firewall