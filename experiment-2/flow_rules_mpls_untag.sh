#!/bin/sh

# This script generates two tables for unpacking MPLS-tagged packets
# Tabel 1 loads the broadcast-flag and the original sender into memory, submitting into to table 1
# table 2 is used to restore the previous ethertype, resubmitting the packet to table 10 for further processing

# First bit of metadata is broadcast-flag
ovs-ofctl  add-flow iot "table=1, eth_type=0x8848 actions=load:1->metadata[0],move:mpls_label->metadata[1..20],pop_mpls:0x8847,resubmit(,2)"
ovs-ofctl  add-flow iot "table=1, eth_type=0x8847 actions=load:0->metadata[0],move:mpls_label->metadata[1..20],pop_mpls:0x8847,resubmit(,2)"

# Restore ethertype based on MPLS-Tabel
# Note that table 1 modififed the ethertype to be 0x8847 no matter if it is broadcast or not
# Unfortunatly, eth_type is read-only in OpenVSwitch, so there's static table
# For table c.f. https://en.wikipedia.org/wiki/EtherType

#0x0800 	Internet Protocol version 4 (IPv4)
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x0800, actions=pop_mpls:0x0800,resubmit(,10)"

#0x0806 	Address Resolution Protocol (ARP)
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x0806, actions=pop_mpls:0x0806,resubmit(,10)"

#0x0842 	Wake-on-LAN[8]
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x0842, actions=pop_mpls:0x0842,resubmit(,10)"

#0x2000 	Cisco Discovery Protocol[citation needed]
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x2000, actions=pop_mpls:0x2000,resubmit(,10)"

#0x22EA 	Stream Reservation Protocol
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x22EA, actions=pop_mpls:0x22EA,resubmit(,10)"

#0x22F0 	Audio Video Transport Protocol (AVTP)
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x22F0, actions=pop_mpls:0x22F0,resubmit(,10)"

#0x22F3 	IETF TRILL Protocol
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x22F3, actions=pop_mpls:0x22F3,resubmit(,10)"

#0x6002 	DEC MOP RC
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x6002, actions=pop_mpls:0x6002,resubmit(,10)"

#0x6003 	DECnet Phase IV, DNA Routing
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x6002, actions=pop_mpls:0x6002,resubmit(,10)"

#0x6004 	DEC LAT
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x6004, actions=pop_mpls:0x6004,resubmit(,10)"

#0x8035 	Reverse Address Resolution Protocol (RARP)
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x8035, actions=pop_mpls:0x8035,resubmit(,10)"

#0x809B 	AppleTalk (EtherTalk)
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x809B, actions=pop_mpls:0x809B,resubmit(,10)"

#0x80D5 	LLC PDU (in particular, IBM SNA), preceded by 2 bytes length and 1 byte padding[9]
# Ingnore LLC, because this is used by the SDN internally

#0x80F3 	AppleTalk Address Resolution Protocol (AARP)
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x80F3, actions=pop_mpls:0x80F3,resubmit(,10)"

#0x8100 	VLAN-tagged frame (IEEE 802.1Q) and Shortest Path Bridging IEEE 802.1aq with NNI compatibility[10]
# Ignore L2-Management

#0x8102 	Simple Loop Prevention Protocol (SLPP)
# Ignore L2-Management

#0x8103 	Virtual Link Aggregation Control Protocol (VLACP)

#0x8137 	IPX
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x8137, actions=pop_mpls:0x8137,resubmit(,10)"

#0x8204 	QNX Qnet
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x8204, actions=pop_mpls:0x8204,resubmit(,10)"

#0x86DD 	Internet Protocol Version 6 (IPv6)
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x86DD, actions=pop_mpls:0x86DD,resubmit(,10)"

#0x8808 	Ethernet flow control
# Ignore L2-Management

#0x8809 	Ethernet Slow Protocols[11] such as the Link Aggregation Control Protocol (LACP)
# Ignore L2-Management

#0x8819 	CobraNet
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x8819, actions=pop_mpls:0x8819,resubmit(,10)"

#0x8847 	MPLS unicast
# Ingore MPLS

#0x8848 	MPLS multicast
# Ignore MPLS

#0x8863 	PPPoE Discovery Stage
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x8863, actions=pop_mpls:0x8863,resubmit(,10)"

#0x8864 	PPPoE Session Stage
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x8864, actions=pop_mpls:0x8864,resubmit(,10)"

#0x887B 	HomePlug 1.0 MME
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x887B, actions=pop_mpls:0x887B,resubmit(,10)"

#0x888E 	EAP over LAN (IEEE 802.1X)
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x888E, actions=pop_mpls:0x888E,resubmit(,10)"

#0x8892 	PROFINET Protocol
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x8892, actions=pop_mpls:0x8892,resubmit(,10)"

#0x889A 	HyperSCSI (SCSI over Ethernet)
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x889A, actions=pop_mpls:0x889A,resubmit(,10)"

#0x88A2 	ATA over Ethernet
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x88A2, actions=pop_mpls:0x88A2,resubmit(,10)"

#0x88A4 	EtherCAT Protocol
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x88A4, actions=pop_mpls:0x88A4,resubmit(,10)"

#0x88A8 	Service VLAN tag identifier (S-Tag) on Q-in-Q tunnel
# Ignore, vlan tagging cannot be transmitted accross WLAN

#0x88AB 	Ethernet Powerlink[citation needed]
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x88AB, actions=pop_mpls:0x88AB,resubmit(,10)"

#0x88B8 	GOOSE (Generic Object Oriented Substation event)
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x88B8, actions=pop_mpls:0x88B8,resubmit(,10)"

#0x88B9 	GSE (Generic Substation Events) Management Services
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x88B9, actions=pop_mpls:0x88B9,resubmit(,10)"

#0x88BA 	SV (Sampled Value Transmission)
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x88BA, actions=pop_mpls:0x88BA,resubmit(,10)"

#0x88BF 	MikroTik RoMON (unofficial)
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x88BF, actions=pop_mpls:0x88BF,resubmit(,10)"

#0x88CC 	Link Layer Discovery Protocol (LLDP)
# Ignore L2-Management

#0x88CD 	SERCOS III
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x88CD, actions=pop_mpls:0x88CD,resubmit(,10)"

#0x88E1 	HomePlug Green PHY
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x88E1, actions=pop_mpls:0x88E1,resubmit(,10)"

#0x88E3 	Media Redundancy Protocol (IEC62439-2)
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x88E3, actions=pop_mpls:0x88E3,resubmit(,10)"

#0x88E5 	IEEE 802.1AE MAC security (MACsec)
# Ingore L2-Management

#0x88E7 	Provider Backbone Bridges (PBB) (IEEE 802.1ah)
# Ingore L2-Management

#0x88F7 	Precision Time Protocol (PTP) over IEEE 802.3 Ethernet
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x88F7, actions=pop_mpls:0x88F7,resubmit(,10)"

#0x88F8 	NC-SI
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x88F8, actions=pop_mpls:0x88F8,resubmit(,10)"

#0x88FB 	Parallel Redundancy Protocol (PRP)
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x88FB, actions=pop_mpls:0x88FB,resubmit(,10)"

#0x8902 	IEEE 802.1ag Connectivity Fault Management (CFM) Protocol / ITU-T Recommendation Y.1731 (OAM)
# Ignore L2-Management

#0x8906 	Fibre Channel over Ethernet (FCoE)
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x8906, actions=pop_mpls:0x8906,resubmit(,10)"

#0x8914 	FCoE Initialization Protocol
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x8914, actions=pop_mpls:0x8914,resubmit(,10)"

#0x8915 	RDMA over Converged Ethernet (RoCE)
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x8915, actions=pop_mpls:0x8915,resubmit(,10)"

#0x891D 	TTEthernet Protocol Control Frame (TTE)
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x891D, actions=pop_mpls:0x891D,resubmit(,10)"

#0x893a 	1905.1 IEEE Protocol
ovs-ofctl  add-flow iot "table=2, eth_type=0x8847,mpls_label=0x893a, actions=pop_mpls:0x893a,resubmit(,10)"

#0x892F 	High-availability Seamless Redundancy (HSR)
# Ignore L2-Management

#0x9000 	Ethernet Configuration Testing Protocol[12]
# Ignore L2-Management

#0xF1C1 	Redundancy Tag (IEEE 802.1CB Frame Replication and Elimination for Reliability) 
# Ignore L2-Management
