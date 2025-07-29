# Experiment 2

Experiment 2 verifies that commercial-off-the-shelf smart home IoT devices are fully functional in the isolation environment.

This is more challenging, because the on-boarding procedures of smart home equipment may involve connecting and 
disconnecting devices from the network. This results in establishing and terminating RSNA/WPA session, which will 
in consequence attach / de-attach ports at the OpenVSwitch (OVS) bridge.

For the TP-Link kasa HS110 smart plug the process is follows

0. Precondition: smartphone is connected to WLAN, Plug is not
1. User opens companion app and starts onboarding process
2. App asks users to put plug into pairing mode (press button 5 secs)
3. App asks user to disconnect from its regular WLAN and connect to the onboarding-WLAN hosted at the plug instead
4. App asks user for WLAN credentials and sends them to the smart plug
5. Smart Plug connects to the WLAN, App asks user to connect to his / her regular home WLAN.
6. Both app and smart plug contact the vendor's cloud and finalize the process.

The OVS bridge reacts to port changes in steps 3., 4. and 5. These changes are at odds with the static configuration in experiment-1. 
Rules for the association of the plug cannot be configured before the plug connects initially. Rules for the smartphone may not be valid after reconnecting the phone in step 5.

To overcome this limitation, and ryu-based Software Defined Networking (SDN) application reacts to all changes. 
The application is included in the [ryu_scripts](ryu_scripts) folder. `main.py` is the entry-point for handling the events.

The experiment comprises manually onboarding a HS110 plug and toggling the light switch.

In result, the operation was performed correctly. The log of the SDN-application is places at [results/controller_log.txt](results/controller_log.txt).

