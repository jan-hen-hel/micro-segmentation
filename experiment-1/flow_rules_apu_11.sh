#!/bin/sh

# Rules for APU-11 (Gateway)

ovs-ofctl del-flows iot

# APU has two giot devices: APU-20 and APU-21
# Both are isolated. There is nothing local. Hence, after ingress filtering (to prevent MAC-spoofing) all traffic is forwarded to the MAC-interface

# Outgoing
## 1. check multicast bit. We're handling multicast as broadcast, here. 
# No optimizations.

## APU-GIOT-20
ovs-ofctl add-flow iot "table=0, in_port=iot_20, dl_src=00:0A:52:06:E4:32, dl_dst=01:00:00:00:00:00/01:00:00:00:00:00, actions=push_mpls:0x8848,set_mpls_label=0x20,iotupl"

## APU-GIOT-21
ovs-ofctl add-flow iot "table=0, in_port=iot_21, dl_src=00:0A:52:06:E4:2A, dl_dst=01:00:00:00:00:00/01:00:00:00:00:00, actions=push_mpls:0x8848,set_mpls_label=0x21,iotupl"

## Same rule for unicast-traffic. Prevent MAC-Spoofing by ingres Filter and ecapsulate
## APU-GIOT-20
ovs-ofctl add-flow iot "table=0, in_port=iot_20, dl_src=00:0A:52:06:E4:32, actions=push_mpls:0x8847,set_mpls_label=0x20,iotupl"

## APU-GIOT-21
ovs-ofctl add-flow iot "table=0, in_port=iot_21, dl_src=00:0A:52:06:E4:2A, actions=push_mpls:0x8847,set_mpls_label=0x21,iotupl"

# Incoming

# Broadcast-Traffic from Gateway
ovs-ofctl add-flow iot "table=0, in_port=iotupl, eth_type=0x8848,mpls_label=0x10, actions=pop_mpls:0x8848,iot_20, iot_21"
# Broadcast-Traffic from APU-22 to APU-20
ovs-ofctl add-flow iot "table=0, in_port=iotupl, eth_type=0x8847,mpls_label=0x22, actions=pop_mpls:0x8847,iot_20"

# Unicast-Traffic from Gateway to APU-20
ovs-ofctl add-flow iot "table=0, in_port=iotupl,dl_dst=00:0A:52:06:E4:32, eth_type=0x8847,mpls_label=0x10, actions=pop_mpls:0x8847, iot_20"

# Unicast-Traffic from Gateway to APU-21
ovs-ofctl add-flow iot "table=0, in_port=iotupl,dl_dst=00:0A:52:06:E4:2A, eth_type=0x8847,mpls_label=0x10, actions=pop_mpls:0x8847, iot_21"

# Unicast-Traffic from APU-22 to APU-20
ovs-ofctl add-flow iot "table=0, in_port=iotupl,dl_dst=00:0A:52:06:E4:32, eth_type=0x8847,mpls_label=0x22, actions=pop_mpls:0x8847, iot_20"

