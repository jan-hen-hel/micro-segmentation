#!/bin/sh

# Generic install
./install.sh

# APU-11 is not an internet-gateway. No DHCP or routing, hence

echo "Set SSID to iot-lan-apu-11 to distinguish smart home mesh stations"
uci set wireless.iot.ssid='iot-lan-apu-11'
uci commit wireless
wifi

echo "Setting iot-interface address to 198.19.4.11"
uci set network.iot.ipaddr='198.19.4.11'
uci commit network