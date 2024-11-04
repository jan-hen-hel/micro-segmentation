#!/bin/sh

# Rules for APU-12 (Mesh-Node)
ovs-ofctl --protocols=OpenFlow13 del-flows iot

# APU has two giot devices: APU-22
# Both are isolated. There is nothing local. Hence, after ingress filtering (to prevent MAC-spoofing) all traffic is forwarded to the MAC-interface

# Outgoing
## 1. check multicast bit. We're handling multicast as broadcast, here. 
# No optimizations.

## APU-GIOT-22
ovs-ofctl --protocols=OpenFlow13 add-flow iot "table=0, in_port=iot_22, dl_src=00:0A:52:06:E4:31, dl_dst=01:00:00:00:00:00/01:00:00:00:00:00, actions=move:eth_type->metadata[0..15],push_mpls:0x8848,move:metadata[0..15]->mpls_label[0..15],push_mpls:0x8848,set_mpls_label=22,iotupl"


## Same rule for unicast-traffic. Prevent MAC-Spoofing by ingres Filter and ecapsulate
## APU-GIOT-22
ovs-ofctl --protocols=OpenFlow13 add-flow iot "table=0, in_port=iot_22, dl_src=00:0A:52:06:E4:31, actions=move:eth_type->metadata[0..15],push_mpls:0x8848,move:metadata[0..15]->mpls_label[0..15],push_mpls:0x8847,set_mpls_label=22,iotupl"

# Incoming

# Broadcast-Traffic from Gateway
ovs-ofctl --protocols=OpenFlow13 add-flow iot "table=0, in_port=iotupl, eth_type=0x8848,mpls_label=10, actions=pop_mpls:0x8848,move:mpls_label[0..15]->metadata[0..15],pop_mpls:metadata[0..15],iot_22"
# Broadcast-Traffic from APU-22 to APU-20
ovs-ofctl --protocols=OpenFlow13 add-flow iot "table=0, in_port=iotupl, eth_type=0x8847,mpls_label=21, actions=pop_mpls:0x8847,iot_22"

# Unicast-Traffic from Gateway to APU-22
ovs-ofctl --protocols=OpenFlow13 add-flow iot "table=0, in_port=iotupl,dl_dst=00:0A:52:06:E4:31, eth_type=0x8847,mpls_label=0x10, actions=pop_mpls:0x8847, iot_22"

# Unicast-Traffic from APU-22 to APU-20
ovs-ofctl --protocols=OpenFlow13 add-flow iot "table=0, in_port=iotupl,dl_dst=00:0A:52:06:E4:31, eth_type=0x8847,mpls_label=0x20, actions=pop_mpls:0x8847, iot_22"

