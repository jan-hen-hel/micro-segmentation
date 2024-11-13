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

ovs-ofctl add-flow iot "table=0, in_port=iot_31, dl_src=f8:ad:cb:03:8e:ea, dl_dst=01:00:00:00:00:00/01:00:00:00:00:00, actions=move:eth_type->metadata[0..15],push_mpls:0x8848,move:metadata[0..15]->mpls_label[0..15],push_mpls:0x8848,set_mpls_label=31,iotupl"


## Unicast
## Same rule for unicast-traffic. Prevent MAC-Spoofing by ingres Filter and encapsulate
ovs-ofctl add-flow iot "table=0, in_port=iot_31, dl_src=f8:ad:cb:03:8e:ea, actions=move:eth_type->metadata[0..15],push_mpls:0x8848,move:metadata[0..15]->mpls_label[0..15],push_mpls:0x8847,set_mpls_label=31,iotupl"


# Incoming 
## iot upl - remove MPLS
ovs-ofctl  add-flow iot "table=0, in_port=iotupl, actions=resubmit(,1)"

# Smartphone is exposed - forward any broadcast traffic as well as unicast-traffic
ovs-ofctl  add-flow iot "table=10,metadata[0]=1,actions=iot_31"
ovs-ofctl  add-flow iot "table=10,metadata[0]=0,dl_dst=f8:ad:cb:03:8e:ea,actions=iot_31"
