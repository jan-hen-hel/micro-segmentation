#!/bin/sh

# Generic install
./install.sh

# APU-12 is not an internet-gateway. No DHCP or routing, hence

echo "Set SSID to iot-lan-apu-12 to distinguish smart home mesh stations"
uci set wireless.iot.ssid='iot-lan-apu-12'
uci commit wireless
wifi

echo "Setting iot-interface address to 198.19.4.12"
uci set network.iot.ipaddr='198.19.4.12'
uci commit network

echo "Script completed. Rebooting to apply uci-settings"
reboot