#!/bin/sh

# Generic install
./install.sh

# APU-12 is not an internet-gateway. No DHCP or routing, hence

echo "Set SSID to iot-lan-apu-12 to distinguish smart home mesh stations"
uci set wireless.iot.ssid='iot-lan-apu-12'
uci commit wireless
wifi