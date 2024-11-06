#!/bin/sh

# Rules for APU 10 (Gatway)

ovs-ofctl del-flows iot

# Populate table 1 and 2 for MPLS handling of incoming traffic
sh flow_rules_mpls_untag.sh 
# Both are isolated. There is nothing local. Hence, after ingress filtering (to prevent MAC-spoofing) all traffic is forwarded to the MAC-interface

# Outgoing
## check multicast bit. We're handling multicast as broadcast, here. No optimizations.

# Btw. make sure _not_ forward any traffic from LAN as broadcast. Hence, only use local-port!

ovs-ofctl add-flow iot "table=0, in_port=iot, dl_dst=01:00:00:00:00:00/01:00:00:00:00:00, actions=move:eth_type->metadata[0..15],push_mpls:0x8848,move:metadata[0..15]->mpls_label[0..15],push_mpls:0x8848,set_mpls_label=10,iotupl"

## Same rule for unicast-traffic. 
ovs-ofctl add-flow iot "table=0, in_port=iot, actions=move:eth_type->metadata[0..15],push_mpls:0x8848,move:metadata[0..15]->mpls_label[0..15],push_mpls:0x8847,set_mpls_label=10,iotupl"

# Incoming - iot upl
ovs-ofctl  add-flow iot "table=0, in_port=iotupl, actions=resubmit(,1)"

# All MPLS tagged traffic: Output on iot-Port
ovs-ofctl  add-flow iot "table=10, actions=iot"
