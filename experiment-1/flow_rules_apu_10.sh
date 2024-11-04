#!/bin/sh

# Rules for APU 10 (Gatway)

ovs-ofctl del-flows iot

# Both are isolated. There is nothing local. Hence, after ingress filtering (to prevent MAC-spoofing) all traffic is forwarded to the MAC-interface

# Outgoing
## check multicast bit. We're handling multicast as broadcast, here. No optimizations.

# Btw. make sure _not_ forward any traffic from LAN as broadcast. Hence, only use local-port!

ovs-ofctl add-flow iot "table=0, in_port=iot, dl_dst=01:00:00:00:00:00/01:00:00:00:00:00, actions=push_mpls:0x8848,set_mpls_label=10,iotupl"

## Same rule for unicast-traffic. 
ovs-ofctl add-flow iot "table=0, in_port=iot, actions=push_mpls:0x8847,set_mpls_label=10,iotupl"

# Incoming

# Broadcast-Traffic to Gateway: Output local
ovs-ofctl add-flow iot "table=0, in_port=iotupl, eth_type=0x8848, actions=pop_mpls:0x8848,iot"

# Unicast-Traffic to Gateway: Output local
ovs-ofctl add-flow iot "table=0, in_port=iotupl, eth_type=0x8847, actions=pop_mpls:0x8847,iot"

