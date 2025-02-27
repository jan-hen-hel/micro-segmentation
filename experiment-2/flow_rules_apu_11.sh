#!/bin/sh

# Rules for APU-11 (Mesh-Node)
ovs-ofctl del-flows iot

# Populate table 1 and 2 for MPLS handling of incoming traffic
sh flow_rules_mpls_untag.sh 

# APU has two giot devices: APU-20, APU-21
# Both are isolated. There is nothing local. Hence, after ingress filtering (to prevent MAC-spoofing) all traffic is forwarded to the MAC-interface

# Outgoing
## 1. check multicast bit. We're handling multicast as broadcast, here. 

## Brodcast
## No optimizations.

# Nokia 7.1 smartphone
# Forward broadcast traffic to SmartPlug and Gateway
ovs-ofctl add-flow iot "table=0, in_port=iot_31, dl_src=f8:ad:cb:03:8e:ea, dl_dst=01:00:00:00:00:00/01:00:00:00:00:00, actions=iot_32,move:eth_type->metadata[0..15],push_mpls:0x8848,move:metadata[0..15]->mpls_label[0..15],push_mpls:0x8848,set_mpls_label=31,iotupl"

# TP-Link Smart Plug
# Forward broadcast-traffic to Nokia 7.1 and Gateway
ovs-ofctl add-flow iot "table=0, in_port=iot_32, dl_src=1C:3B:F3:A5:51:56, dl_dst=01:00:00:00:00:00/01:00:00:00:00:00, actions=iot_31,move:eth_type->metadata[0..15],push_mpls:0x8848,move:metadata[0..15]->mpls_label[0..15],push_mpls:0x8848,set_mpls_label=32,iotupl"


## Unicast
## Same rule for unicast-traffic. Prevent MAC-Spoofing by ingres Filter and encapsulate
# Allow unicast-traffic between Nokia 7.1 and SmartPlug
ovs-ofctl add-flow iot "table=0, in_port=iot_31, dl_src=f8:ad:cb:03:8e:ea, dl_dst=1C:3B:F3:A5:51:56, iot_32"
ovs-ofctl add-flow iot "table=0, in_port=iot_32, dl_src=1C:3B:F3:A5:51:56, dl_dest=f8:ad:cb:03:8e:ea, iot_31"

# Any other unicast-traffic: Sent to gateway. Note: One could block certain traffic if not directed to MAC-Addresses of the gateway
ovs-ofctl add-flow iot "table=0, in_port=iot_31, dl_src=f8:ad:cb:03:8e:ea, actions=move:eth_type->metadata[0..15],push_mpls:0x8848,move:metadata[0..15]->mpls_label[0..15],push_mpls:0x8847,set_mpls_label=31,iotupl"
ovs-ofctl add-flow iot "table=0, in_port=iot_32, dl_src=1C:3B:F3:A5:51:56, actions=move:eth_type->metadata[0..15],push_mpls:0x8848,move:metadata[0..15]->mpls_label[0..15],push_mpls:0x8848,set_mpls_label=32,iotupl"

# Incoming 
## iot upl - remove MPLS
ovs-ofctl  add-flow iot "table=0, in_port=iotupl, actions=resubmit(,1)"

# Smartphone is exposed - forward any broadcast traffic as well as unicast-traffic
ovs-ofctl  add-flow iot "table=10,metadata[0]=1,actions=iot_31"
ovs-ofctl  add-flow iot "table=10,metadata[0]=0,dl_dst=f8:ad:cb:03:8e:ea,actions=iot_31"

# SmartPlug may connect to smartphone and the internet, handle incoming traffic accordingly

# Internet
ovs-ofctl  add-flow iot "table=10,metadata[0]=0,dl_dst=1C:3B:F3:A5:51:56,actions=iot_32"
