class InitialRulez:

    def push_mpls_broadcast_flag_rules(self,datapath):
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser

        # Matches
        #match_broadcast = parser.OFPMatch(eth_type=0x8848)
        match_unicast = parser.OFPMatch(eth_type=0x8847)

        #broadcast_instruction = [parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS,[
        #    parser.OFPActionSetField(metadata=1),
        #    parser.NXActionRegMove(src_field="mpls_label",dst_field="metadata",n_bits=20, dst_ofs=1),
        #    parser.OFPActionPopMpls(ethertype=0x8847),
        #    parser.NXActionResubmitTable(table_id=2)])]

        unicast_instruction = [parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS,[
        #    parser.OFPActionSetField(metadata=0),
        #    parser.NXActionRegMove(src_field="mpls_label",dst_field="metadata",n_bits=20, dst_ofs=1),
            parser.NXActionRegMove(src_field="mpls_label",dst_field="metadata",n_bits=20, dst_ofs=0), # vlan_id
            parser.OFPActionPopMpls(ethertype=0x8847),
            parser.NXActionResubmitTable(table_id=2)])]

        #broadcast_msg = parser.OFPFlowMod(datapath=datapath, priority=0,table_id=1, match=match_broadcast, instructions=broadcast_instruction)
        unicast_msg = parser.OFPFlowMod(datapath=datapath, priority=0,table_id=1, match=match_unicast, instructions=unicast_instruction)
        #datapath.send_msg(broadcast_msg)
        datapath.send_msg(unicast_msg)


    def push_mpls_untagging_rules(self,datapath):
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser

        eth_types = [
            0x0800, # IPv4
            0x0806, # ARP
#            0x86DD, # Internet Protocol Version 6 (IPv6)
#            0x0842, # Wake-on-LAN
#            0x2000, # Cisco Discovery Protocol
#            0x22EA, # Stream Reservation Protocol
#            0x22F0, # Audio Video Transport Protocol (AVTP)
#            0x22F3, # IETF TRILL Protocol
#            0x6002, # DEC MOP RC
#            0x6003, # DECnet Phase IV, DNA Routing
#            0x6004, # DEC LAT
#            0x8035, # RARP
#            0x809B, # AppleTalk (EtherTalk)
#            # 0x80D5 Ignore LLC, because this is used by the SDN internally
#            0x80F3, # AppleTalk Address Resolution Protocol (AARP)
            # Ignore VLANs 0x8100 #   VLAN - tagged frame
            # 0x8102, # Ignore L2-Management
            # 0x8103 # Ignore L2-Management
#            0x8137, # IPX
#            0x8204, # QNX Qnet
#            0x8808, # Ethernet flow control
#            0x8809, # Ethernet Slow Protocols[11] such as the Link Aggregation Control Protocol (LACP)
#            0x8819, # CobraNet
            # Ignore MPLS 0x8847 0x8848
#            0x8863, # PPPoE Discovery Stage
#            0x8864, # PPPoE Session Stage
#            0x887B, # HomePlug 1.0 MME
#            0x888E, # EAP over LAN (IEEE 802.1X)
#            0x8892, # PROFINET Protocol
#            0x889A, # HyperSCSI (SCSI over Ethernet)
#            0x88A2, # ATA over Ethernet
#            0x88A4, # EtherCAT Protocol
            # Ignore 0x88A8, # Service VLAN tag identifier (S-Tag) on Q-in-Q tunnel
#            0x88B8, # GOOSE (Generic Object Oriented Substation event)
#            0x88B9, # GSE (Generic Substation Events) Management Services
 #           0x88BA, # SV (Sampled Value Transmission)
 #           0x88BF, # MikroTik RoMON (unofficial)
 #           # Ingore L2-Mgmt LLDP 0x88CC
 #           0x88CD, # 	SERCOS III
#            0x88E1, # HomePlug Green PHY
 #           0x88E3, # Media Redundancy Protocol (IEC62439-2)
            # Ignore L2-Mgmt 0x88E5 	IEEE 802.1AE MAC security (MACsec)
            # Ignore L2-Mgmt 0x88E7 	Provider Backbone Bridges (PBB) (IEEE 802.1ah)
 #           0x88F7, # Precision Time Protocol (PTP) over IEEE 802.3 Ethernet
 #           0x88F8, # NC-SI
 #           0x88FB, # Parallel Redundancy Protocol (PRP)
            # Ignore L2-Mgmt 0x8902, # IEEE 802.1ag Connectivity Fault Management (CFM) Protocol / ITU-T Recommendation Y.1731 (OAM)
#            0x8906, # Fibre Channel over Ethernet (FCoE)
#            0x8914, # FCoE Initialization Protocol
#            0x8915, # RDMA over Converged Ethernet (RoCE)
#            0x891D, # TTEthernet Protocol Control Frame (TTE)
#            0x893a, #1905.1 IEEE Protocol
            # Ignore L2-Management 0x892F 	High-availability Seamless Redundancy (HSR)
            # Ignore L2-Management 0x9000 	Ethernet Configuration Testing Protocol[12]
            # Ignore L2-Management 0xF1C1 	Redundancy Tag (IEEE 802.1CB Frame Replication and Elimination for Reliability)
        ]
        for tpe in eth_types:
            match = parser.OFPMatch(eth_type=0x8847, mpls_label=tpe)
            instruction =  [parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS,[
                parser.OFPActionPopMpls(ethertype=tpe),
                parser.NXActionResubmitTable(table_id=10)])]
            msg = parser.OFPFlowMod(datapath=datapath, priority=0,table_id=2, match=match, instructions=instruction)
            datapath.send_msg(msg)

    def push(self,datapath):
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser
        for table in [1,2]:
            msg = parser.OFPFlowMod(datapath, 0, 0, table ,ofproto.OFPFC_DELETE, 0, 0,1,ofproto.OFPCML_NO_BUFFER,ofproto.OFPP_ANY,ofproto.OFPG_ANY, 0,parser.OFPMatch(), [])
            datapath.send_msg(msg)
        self.push_mpls_broadcast_flag_rules(datapath)
        self.push_mpls_untagging_rules(datapath)
