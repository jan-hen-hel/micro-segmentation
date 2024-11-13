# Experiment 1

Experiment 1 is designed as the proof-of-concept experiment showing the general feasibility of the approach. 

* For SmartHome Mesh Points, three APU routers form a wireless mesh (IEEE 802.11 based / WPA3-SAE encrypted) that is utilized as a backbone-like network in the house
* All other APUs are connected and isolated, whereas APU-20 and APU-22 are able to exchange packets.

The topology is shown in the following figure.

TODO: Add picture

## Setting the experiment

### For APU-10, APU-11, APU-12

1. Clone this repository at /srv. The firmware contains a shell-script that supports it.
2. Run the dedicated `apu_NN_install.sh` script, stored at `mesh_router_setup`. The script will install some OpenWRT packages, add some UCI-configuration and reboot the router to apply all configuration-changes
3. Execute `flow_rules_apu_NN.sh` to install dedicated OpenFlow rules on each device. The scripts utilize `ovs-ofctl` to locally generate OpenFLow packages and install them in OpenFlows table

### For APU-20, APU-21, APU-22

1. Connect APU-20 and APU-21 to APU-11 utilizing the IoT-WLAN in AP mode. A dedicated WPA-PSK is stored at `mesh-router-setup/wpa_keys/hostapd.wpa_psk` - check, that the MAC-address of the WLAN-NIC matches.Make sure to create a new `WWAN` interface (firewall-Zone: WAN) when connecting using Luci (e.g. Webbased UI)
2. Connect APU-22 to APU-12 in the same manner.

This results in utilizing 198.19.4.0/24 for the experiments

## Running the experiment

The configuration is benchmarked by a simple ICMP-ECHO (i.e. ping) reachability testing.
Due to isolating APU-21 from APU-20 and APU-22:

1. All APUs must be able to reach the internet
2. APU-20 is able to reach APU-22
3. APU-22 is able to reach APU-20
4. APU-21 must not be able to reach any other APU

These scripts run the reachability tests on the APU boards.
*Note: The name must be replaced with the ip-address of the corresponding apu

### APU-20

```bash
date
echo "Checking ARP-Table. No GIOT-APU should be present"
arp -n
echo "Trying to reach APU-21. this should fail"
ping -c 1 apu21
echo "Trying to reach APU-22. this should succeed"
ping -c 1 apu22 
echo "Trying to reach Google DNS. this should succeed"
ping -c 1 8.8.8.8
echo "Checking ARP-Table. APU-21 should not be known"
arp -n
```

### APU-21
```bash
date
echo "Checking ARP-Table. No GIOT-APU should be present"
arp -n
echo "Trying to reach APU-21. this should fail"
ping -c 1 apu20
echo "Trying to reach APU-22. this should fail"
ping -c 1 apu22 
echo "Trying to reach Google DNS. this should succeed"
ping -c 1 8.8.8.8
echo "Checking ARP-Table. APU-20 and APU-20 should not be known"
arp -n
```

### APU-22
```bash
date
echo "Checking ARP-Table. No GIOT-APU should be present"
arp -n
echo "Trying to reach APU-20. this should succeed"
ping -c 1 apu20
echo "Trying to reach APU-21. this should fail"
ping -c 1 apu21 
echo "Trying to reach Google DNS. this should succeed"
ping -c 1 8.8.8.8
echo "Checking ARP-Table. APU-21 should not be known"
arp -n
```

## Results

See results folder for a dedicated per APU log.