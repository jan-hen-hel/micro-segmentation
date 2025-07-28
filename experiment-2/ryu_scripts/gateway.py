import logging

# A gateway-device for providing connectivity for the iot-port
# Without loss of generality, gateways are not reponsible for providing IoT-WLAN connectivity.
# While this can be done in general, it is not in focus of this work; the feasibility of this approach has been demonstrated before
class Gateway():

    def __init__(self,ports):
        self.iot_port_num = -1
        self.iot_upl_port_num = -1
        for port_num in ports:
            port = ports[port_num]
            if (port.name == b'iot'):
                self.port = port
                self.iot_port_num = port.port_no
            if (port.name == b'iotupl'):
                self.iot_upl_port_num = port.port_no

        if (self.iot_port_num == -1):
            logging.error("Gateway without IoT-Port - data: %s", ports)
            #raise "Gateway without IoT-Port"


    def onConnect(self,datapath):
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser
        
        # Clear table 0 and 10 - both are used
        for table in [0,10]:
            msg = parser.OFPFlowMod(datapath, 0, 0, table ,ofproto.OFPFC_DELETE, 0, 0,1,ofproto.OFPCML_NO_BUFFER,ofproto.OFPP_ANY,ofproto.OFPG_ANY, 0,parser.OFPMatch(), [])
            datapath.send_msg(msg)

        # Table 0 - a gateway has no local device. Hence, all traffic is passed to the mesh
        ## 1st: Broadcast-traffic

            
        # Matches
        #match_broadcast = parser.OFPMatch(in_port=self.iot_port_num, eth_dst=("01:00:00:00:00:00","01:00:00:00:00:00"))
        match_unicast = parser.OFPMatch(in_port=self.iot_port_num)

        # There is also the situation in which the packets don't travel via input
        # Here, have a second rule for the local MAC



        #broadcast_instruction = [parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS,[
        #    parser.NXActionRegMove(src_field="eth_type",dst_field="metadata",n_bits=16, dst_ofs=0),
        #    parser.OFPActionPushMpls(0x8848),
        #    parser.NXActionRegMove(src_field="metadata",dst_field="mpls_label",n_bits=15, dst_ofs=0),
        #    parser.OFPActionPushMpls(0x8848),
        #    parser.OFPActionSetField(mpls_label=10),
        #    parser.OFPActionOutput(port=self.iot_upl_port_num)
        #   ])]
        
        unicast_instruction = [parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS,[
            parser.NXActionRegMove(src_field="eth_type",dst_field="metadata",n_bits=16, dst_ofs=0),
            parser.OFPActionPushMpls(0x8847),
            parser.NXActionRegMove(src_field="metadata",dst_field="mpls_label",n_bits=16, dst_ofs=0),
            parser.OFPActionPushMpls(0x8847),
            parser.OFPActionSetField(mpls_label=0x10), # 10: vlan-id of gateway
            parser.OFPActionOutput(port=self.iot_upl_port_num)
            ])]

        #broadcast_msg = parser.OFPFlowMod(datapath=datapath, priority=0,table_id=0, match=match_broadcast, instructions=broadcast_instruction)
        #unicast_msg = parser.OFPFlowMod(datapath=datapath, priority=0,table_id=0, match=match_unicast, instructions=unicast_instruction)
        unicast_msg = parser.OFPFlowMod(datapath=datapath, priority=0,table_id=0, match=match_unicast, instructions=unicast_instruction)

        #datapath.send_msg(broadcast_msg)
        datapath.send_msg(unicast_msg)

        # Incoming traffic on iotupl must be mpls-tag-remoged
        incoming_iot_match = parser.OFPMatch(in_port=self.iot_upl_port_num)
        mpls_untagging_instruction = [parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS,[
            parser.NXActionResubmitTable(table_id=1)
        ])]

        incoming_iotupl_msg =  parser.OFPFlowMod(datapath=datapath, priority=0,table_id=0, match=incoming_iot_match, instructions=mpls_untagging_instruction)
        datapath.send_msg(incoming_iotupl_msg)
        
        #  Output incoming traffic to IoT-Table
        output_instructions = [parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS,[
            parser.OFPActionOutput(port=self.iot_port_num)
        ])]

        datapath.send_msg(parser.OFPFlowMod(datapath=datapath, priority=0,table_id=10,instructions=output_instructions))
