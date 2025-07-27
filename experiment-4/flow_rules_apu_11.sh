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
ovs-ofctl add-flow iot "table=0, in_port=iot_20, dl_src=00:0A:52:06:E4:32, dl_dst=01:00:00:00:00:00/01:00:00:00:00:00, actions=move:eth_type->metadata[0..15],push_mpls:0x8848,move:metadata[0..15]->mpls_label[0..15],push_mpls:0x8848,set_mpls_label=20,iotupl"
ovs-ofctl add-flow iot "table=0, in_port=iot_21, dl_src=00:0A:52:06:E4:2A, dl_dst=01:00:00:00:00:00/01:00:00:00:00:00, actions=move:eth_type->metadata[0..15],push_mpls:0x8848,move:metadata[0..15]->mpls_label[0..15],push_mpls:0x8848,set_mpls_label=21,iotupl"


## Unicast
## Same rule for unicast-traffic. Prevent MAC-Spoofing by ingres Filter and ecapsulate
ovs-ofctl add-flow iot "table=0, in_port=iot_20, dl_src=00:0A:52:06:E4:32, actions=move:eth_type->metadata[0..15],push_mpls:0x8848,move:metadata[0..15]->mpls_label[0..15],push_mpls:0x8847,set_mpls_label=20,iotupl"
ovs-ofctl add-flow iot "table=0, in_port=iot_21, dl_src=00:0A:52:06:E4:2A, actions=move:eth_type->metadata[0..15],push_mpls:0x8848,move:metadata[0..15]->mpls_label[0..15],push_mpls:0x8847,set_mpls_label=21,iotupl"


# Incoming 
## iot upl - remove MPLS
ovs-ofctl  add-flow iot "table=0, in_port=iotupl, actions=resubmit(,1)"

## Broadcast-Traffic from Gateway
ovs-ofctl  add-flow iot "table=10,metadata[1..20]=10,metadata[0]=1,actions=iot_20,iot_21"

## Unicast-Traffic from Gateway
ovs-ofctl  add-flow iot "table=10,metadata[1..20]=10,metadata[0]=0,dl_dst=00:0A:52:06:E4:32,actions=iot_20"
ovs-ofctl  add-flow iot "table=10,metadata[1..20]=10,metadata[0]=0,dl_dst=00:0A:52:06:E4:2A,actions=iot_21"

## Traffic from APU-22 to APU-20
ovs-ofctl  add-flow iot "table=10,metadata[1..20]=22,actions=iot_20"

