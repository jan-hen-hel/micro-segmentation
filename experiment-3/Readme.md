# Experiment 3 - Isolation

This experiment verifies that device isolation is cryptographically secure. Due to debugging limitations of the wpa_supplicant package in
OpenWRT two Raspberry PI (RPI) device are used in this experiment. It utilizes APU-11 from the topology of experiment 1.

Both devices are running Raspberry PI OS Lite (release date 13 May 2025). One device is a model 3b, the other is model 4b.

The experiment consist of two parts:

1. WPA2 4-way handshake, both RPI devices are assigned to different VLANs, resulting in different cryptographic keys
2. WPA2 4-way handshake, Both RPI-devices are assign to the same VLAN, resulting in an identical group key

All configuration files are stored in the support-files folder. Console logs are provided in the dedicated experiment folders