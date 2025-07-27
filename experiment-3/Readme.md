# Experiment 3 - Isolation

This experiment verifies that device isolation is cryptographically secure. Due to debugging limitations of the wpa_supplicant package in
OpenWRT two Raspberry PI (RPI) device are used in this experment.

Both devices are running Raspberry PI OS Lite (release date 13 May 2025). One device is a model 3b, the other is model 4b.

The experiment consist of two parts:

1. Both RPI devices are assigned to different VLANs, resulting in different cryptographic keys
2. Both RPI-devices are assign to the same VLAN, resulting in an identical group key

All configuration files are stored in the support-files folder. Console logs are provided in the dedicated experiment folders