#!/bin/sh

# Generic install
./install.sh

# APU-10 is the internet-gateway. It has an DHCP-Service and is forwarding packets to the internet

echo "Enabling DHCP-service on APU-10"
uci -m import dhcp < apu_10_dhcp.uci
uci commit dhcp

echo "Adding Firewall-Rule for iot-forwarding"
uci -m import firewall < apu_10_firewall.uci
uci commit firewall

echo "Set SSID to iot-lan-apu-10 to distinguish smart home mesh stations"
uci set wireless.iot.ssid='iot-lan-apu-10'
uci commit wireless
wifi

echo "Setting iot-interface address to 198.19.4.10"
uci set network.iot.ipaddr='198.19.4.10'
uci commit network