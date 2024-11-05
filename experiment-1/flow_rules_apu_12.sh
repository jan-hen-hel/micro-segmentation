#!/bin/sh

# Rules for APU-12 (Mesh-Node)
ovs-ofctl del-flows iot

# Populate table 1 and 2 for MPLS handling of incoming traffic
sh flow_rules_mpls_untag.sh 

# APU has two giot devices: APU-22
# Both are isolated. There is nothing local. Hence, after ingress filtering (to prevent MAC-spoofing) all traffic is forwarded to the MAC-interface

# Outgoing
## 1. check multicast bit. We're handling multicast as broadcast, here. 
# No optimizations.

## APU-GIOT-22
ovs-ofctl add-flow iot "table=0, in_port=iot_22, dl_src=00:0A:52:06:E4:31, dl_dst=01:00:00:00:00:00/01:00:00:00:00:00, actions=move:eth_type->metadata[0..15],push_mpls:0x8848,move:metadata[0..15]->mpls_label[0..15],push_mpls:0x8848,set_mpls_label=22,iotupl"


## Same rule for unicast-traffic. Prevent MAC-Spoofing by ingres Filter and ecapsulate
## APU-GIOT-22
ovs-ofctl add-flow iot "table=0, in_port=iot_22, dl_src=00:0A:52:06:E4:31, actions=move:eth_type->metadata[0..15],push_mpls:0x8848,move:metadata[0..15]->mpls_label[0..15],push_mpls:0x8847,set_mpls_label=22,iotupl"

# Incoming - iot upl
ovs-ofctl  add-flow iot "table=0, in_port=iotupl, actions=resubmit(,1)"

# Traffic from Gateway
ovs-ofctl  add-flow iot "table=10,metadata[1..20]=10,actions=iot_22"

# Traffic from APU-22 to APU-20
ovs-ofctl  add-flow iot "table=10,metadata[1..20]=20,actions=iot_22"

