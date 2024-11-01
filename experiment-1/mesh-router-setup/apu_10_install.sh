#!/bin/sh

# Generic install
./install.sh

# APU-10 is the internet-gateway. It has an DHCP-Service and is forwarding packets to the internet

echo "Enabling DHCP-service on APU-10"
uci -m import dhcp < apu_10_dhcp.uci

echo "Adding Firewall-Rule for iot-forwarding"
uci -m import firewall < apu_10_firewall_forward.uci
uci commit firewall

echo "Set SSID to iot-lan-apu-10 to distinguish smart home mesh stations"
uci set wireless.iot.ssid='iot-lan-apu-10'
uci commit wireless
wifi