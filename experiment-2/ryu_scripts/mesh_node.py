class MeshNode():

    vlan_to_mac = {
        'iot_31': 'f8:ad:cb:03:8e:ea',
        'iot_32': '1C:3B:F3:A5:51:56'
    }

    allowed_iot_traffic = [
        ["iot_31","iot_32"]
    ]


    def __init__(self, datapath):
        ports = datapath.ports
        self.connected_vlans = {}
        self.datapath = datapath
        for port_num in ports:
            port = ports[port_num]
            if (port.name == b'iotupl'):
                self.iot_upl_port_num = port.port_no
            elif port.name.startswith(b'iot_'):
                self.connected_vlans[port.name] = port.port_no

    def push_initial(self):
        datapath = self.datapath
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser

        # Flush table 0 and 10, because they are needed.
        for table in [0,10]:
            msg = parser.OFPFlowMod(datapath, 0, 0, table ,ofproto.OFPFC_DELETE, 0, 0,1,ofproto.OFPCML_NO_BUFFER,ofproto.OFPP_ANY,ofproto.OFPG_ANY, 0,parser.OFPMatch(), [])
            datapath.send_msg(msg)

        # Incomping MPLS-traffic must be passed to de-tagging
        incoming_iot_match = parser.OFPMatch(in_port=self.iot_upl_port_num)
        mpls_untagging_instruction = [parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS,[
            parser.NXActionResubmitTable(table_id=1)
        ])]

        incoming_iotupl_msg =  parser.OFPFlowMod(datapath=datapath, priority=0,table_id=0, match=incoming_iot_match, instructions=mpls_untagging_instruction)
        datapath.send_msg(incoming_iotupl_msg)
        self.update_port_rules()


    def add_port(self, portname):
        self.connected_vlans.add(portname)
        self.update_port_rules()
    
    def remove_port(self, portname):
        self.connected_vlans.add(portname)
        self.update_port_rules()
    
    def update_port_rules(self):
        datapath = self.datapath
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser
        # Most rules depend on ports that can be present. Hence, rules need to take all ports into account.
        
        all_ports_numbers = self.connected_vlans.values()
        
        # 1. Brodcast-Traffic needs to reach all port
        incoming_iot_match = parser.OFPMatch(metadata=0x11010) # First bit: broadcast.
