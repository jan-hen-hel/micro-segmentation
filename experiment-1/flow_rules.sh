#!/bin/sh

ovs-ofctl del-flows iot

# giot-apu-20 has ID 20. tt may reach APU-22 and the gateway

ovs-ofctl add-flow iot "in_port=iotupl,eth_type=0x8847,mpls_label=20,actions=pop_mpls:0x8847,iot_22,local"
ovs-ofctl add-flow iot "in_port=iot_20,actions=iot_22,local,"

