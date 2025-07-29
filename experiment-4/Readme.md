# Experiment 4 - MAC Spoofing

Experiment 4 is based on experiment 1. In this experiment, GIOT-21 tries to impersonate GIOT-20 by changing its spoofing its MAC.
For simplicity, GIOT-20 is offline during the experiment. It utilizes APU-11 from the topology of experiment 1.

The log is shown below

## 1. Preparation - verify that GIOT-21 is able to connect to APU-11 using its credentials

### Shell on GIOT-21

```bash
wpa_supplicant -c wpa_supplicant.conf -i wl0
Successfully initialized wpa_supplicant
no PHY for ifname wl0
wl0: SME: Trying to authenticate with 02:0a:52:0b:a1:ba (SSID='iot-lan-apu-11' freq=2437 MHz)
no PHY for ifname wl0
wl0: Trying to associate with 02:0a:52:0b:a1:ba (SSID='iot-lan-apu-11' freq=2437 MHz)
no PHY for ifname wl0
no PHY for ifname wl0
wl0: Associated with 02:0a:52:0b:a1:ba
wl0: CTRL-EVENT-SUBNET-STATUS-UPDATE status=0
no PHY for ifname wl0
wl0: Unknown event 37
no PHY for ifname wl0
no PHY for ifname wl0
wl0: WPA: Key negotiation completed with 02:0a:52:0b:a1:ba [PTK=CCMP GTK=CCMP]
wl0: CTRL-EVENT-CONNECTED - Connection to 02:0a:52:0b:a1:ba completed [id=0 id_str=]
no PHY for ifname wl0
wl0: Unknown event 37
```

### Log on APU-11

```
Sun Jul 27 16:16:32 2025 daemon.info hostapd: phy0-ap1: STA 00:0a:52:06:e4:2a IEEE 802.11: authenticated
Sun Jul 27 16:16:32 2025 daemon.info hostapd: phy0-ap1: STA 00:0a:52:06:e4:2a IEEE 802.11: associated (aid 1)
Sun Jul 27 16:16:33 2025 daemon.notice hostapd: Assigned VLAN ID 21 from wpa_psk_file to 00:0a:52:06:e4:2a
Sun Jul 27 16:16:33 2025 daemon.notice hostapd: phy0-ap1: AP-STA-CONNECTED 00:0a:52:06:e4:2a auth_alg=open
Sun Jul 27 16:16:33 2025 daemon.info hostapd: phy0-ap1: STA 00:0a:52:06:e4:2a RADIUS: starting accounting session 87F385D86877D765
Sun Jul 27 16:16:33 2025 daemon.info hostapd: phy0-ap1: STA 00:0a:52:06:e4:2a WPA: pairwise key handshake completed (RSN)
Sun Jul 27 16:16:33 2025 daemon.notice hostapd: phy0-ap1: EAPOL-4WAY-HS-COMPLETED 00:0a:52:06:e4:2a
Sun Jul 27 16:16:33 2025 kern.info kernel: [  136.983688] device iot_21 entered promiscuous mode
```

## 2. MAC-spoofing before connecting

GIOT-21 tries to change its MAC before connecting. The attacker does not know the password that is configured on GIOT-20.
Thus, the connection-attempt is rejected

### Shell on GIOT-21

```bash
root@apu-giot-21:~# ifconfig wl0 hw ether 00:0A:52:06:E4:32
root@apu-giot-21:~# wpa_supplicant -c wpa_supplicant.conf -i wl0
Successfully initialized wpa_supplicant
no PHY for ifname wl0
wl0: SME: Trying to authenticate with 02:0a:52:0b:a1:ba (SSID='iot-lan-apu-11' freq=2437 MHz)
no PHY for ifname wl0
wl0: Trying to associate with 02:0a:52:0b:a1:ba (SSID='iot-lan-apu-11' freq=2437 MHz)
no PHY for ifname wl0
no PHY for ifname wl0
wl0: Associated with 02:0a:52:0b:a1:ba
no PHY for ifname wl0
wl0: CTRL-EVENT-SUBNET-STATUS-UPDATE status=0
wl0: Unknown event 37
no PHY for ifname wl0
wl0: Unknown event 37
no PHY for ifname wl0
wl0: Unknown event 37
no PHY for ifname wl0
wl0: Unknown event 37
wl0: CTRL-EVENT-DISCONNECTED bssid=02:0a:52:0b:a1:ba reason=15
wl0: WPA: 4-Way Handshake failed - pre-shared key may be incorrect
wl0: CTRL-EVENT-SSID-TEMP-DISABLED id=0 ssid="iot-lan-apu-11" auth_failures=1 duration=10 reason=WRONG_KEY
no PHY for ifname wl0
no PHY for ifname wl0
^Cwl0: CTRL-EVENT-DSCP-POLICY clear_all
wl0: CTRL-EVENT-DSCP-POLICY clear_all
nl80211: deinit ifname=wl0 disabled_11b_rates=0
wl0: CTRL-EVENT-TERMINATING
```

### Log on APU-11

```
Sun Jul 27 16:21:43 2025 daemon.info hostapd: phy0-ap1: STA 00:0a:52:06:e4:32 IEEE 802.11: authenticated
Sun Jul 27 16:21:44 2025 daemon.info hostapd: phy0-ap1: STA 00:0a:52:06:e4:32 IEEE 802.11: associated (aid 1)
Sun Jul 27 16:21:44 2025 daemon.notice hostapd: phy0-ap1: AP-STA-POSSIBLE-PSK-MISMATCH 00:0a:52:06:e4:32
Sun Jul 27 16:21:45 2025 daemon.notice hostapd: phy0-ap1: AP-STA-POSSIBLE-PSK-MISMATCH 00:0a:52:06:e4:32
Sun Jul 27 16:21:46 2025 daemon.notice hostapd: phy0-ap1: AP-STA-POSSIBLE-PSK-MISMATCH 00:0a:52:06:e4:32
Sun Jul 27 16:21:47 2025 daemon.notice hostapd: phy0-ap1: AP-STA-POSSIBLE-PSK-MISMATCH 00:0a:52:06:e4:32
Sun Jul 27 16:21:53 2025 daemon.info hostapd: phy0-ap1: STA 00:0a:52:06:e4:32 IEEE 802.11: deauthenticated due to local deauth request
```
