import logging

class MeshNode():

    # To protect from ARP-spoofing, MAC-addresses of devices are utilized for filtering ingress traffic
    # However, for simplicity (WLG) this addresses are not received from hostap-cli, but hardcoded in the script
    # Technically, one could add a MQTT-client to this SDN-controller script, to address changes to MAC-addresses
    # Note, that this wouldn't necessarily cause a different setup: Ingress-Filtering rules need to be updated on port attachment / di-attachment changes
    # Hence, this is more about reducing complexity than about optimizing for performances
    
    # N.B. VLAN and port are sometimes used synmously but have a slightly changed meaning:
    # VLAN has an id (VLANID) that refers to a specific device (e.g. iot_20) having ID=2
    # Port refer's to a port on the switch. It's ID is the dataplane-id in OpenFlow.
    # However, if a device e.g. iot_20 is connected to a port, the respective VLAN is connected in consequence.
    # This results in a port-vlan-duality

    vlan_to_mac = {
        b'iot_31': 'f8:ad:cb:03:8e:ea',
        b'iot_32': '1C:3B:F3:A5:51:56',
        b'iot_20': '00:0A:52:06:E4:32'
    }
    # Additionally, ACL-rules (who may reach whom) are encoded statically
    # Typically, this could be changed by a User-interface 

    allowed_iot_traffic = {
        b"iot_31": [b"iot_32"],
        b"iot_32": [b"iot_31"],
        b"iot_20": []
    }

    # Before going into details, a quick strategy:
    # - Every device (WAN / LAN) has a dedicate port, hence there's a VLAN / device 

    # Table 0 handles incoming packets and distributes them to either table 1, if src-mac matches (local ports) processes them according to ACL
    # Table 1 contains MPLS unwrapping rules. It is initialized by "initial_rules.py" and outside the scope of this script
    # Table 10 contains rules for incoming mesh-packets and switches according the ACL
    # Table 11 has rules for MPLS-tagging of outgoing mesh packets

    # Mesh-Node-Object are constructed when connecting to the SDN-Controller
    # This object holds the state of a switch in the mesh node
    # Essentially, this requires to refresh rules for all conncted devices upon initial connect
    # Due to the object's lifetime, we can keep a reference to the datapath
    def __init__(self, datapath):
        ports = datapath.ports
        self.connected_vlans = {}
        self.datapath = datapath
        self.iot_upl_port_num = None
        logging.info("Iterating ports")
        for port_num in ports: # Initialize all ports
            port = ports[port_num]
            logging.info("Handling port %s",port.name)
            if (port.name == b'iotupl'):
                logging.info("Assigned mesh-uplink port")
                self.iot_upl_port_num = port.port_no # iot-uplink-port - mesh uplink to other mesh devices
            elif port.name.startswith(b'iot_'): # Init an isolated IoT-Port - firtly, build the inventory of all connected ports / vlan
                logging.info("Assigned device port")
                self.connected_vlans[port.name] = port.port_no
            else:
                logging.info("Do not assign rules for port: %s",port.name)


    # Needs to be called from the outside when a port is added
    def onPortAdded(self, portname,dpid):
        logging.info("Addining port - name: %s",portname)
        if (portname == b'iotupl'): # Mesh-Interface went up or down: Take care of uplink rule
            logging.info("Detected iot-uplink port")
            self.iot_upl_port_num = dpid
            self.__init_iotupl_port()
        elif portname.startswith(b'iot_'): # IoT-Device Interface went up 
            logging.info("Detected iot-device port")
            self.connected_vlans[portname] = dpid
            self.__update_port_broadcast_rules()
            self.__update_port_unicast_rules()
        else:
            logging.info("No rules for port: %s", portname)
    
    # Needs to be called from the outside if a port is removed
    def onPortRemoved(self, portname, dpid):
        logging.info("Removing port: %s", portname)
        if (portname == b'iotupl'): # Mesh-Interface went up or down: Take care of uplink rule
            logging.info("Removing mesh-port")
            self.iot_upl_port_num = None
        elif portname.startswith(b'iot_'): # IoT-Device Interface went up 
            logging.info("Removing device port")
            del self.connected_vlans[portname]
            self.__update_port_broadcast_rules()
            self.__update_port_unicast_rules()
        else:
            logging.info("Removing unhandled port")
    

    # On connected is to be called when the device has connected
    # This method pushes initial rulez
    # Note: This not not done by the constructure, to enable unit-Testing
    def onConnect(self):
        logging.info("Running on-connect")
        datapath = self.datapath
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser

        self.__clearTables()

        # Initialize iotport rulez (i.e. rules that need to be re-send after attach / re-attach events)
        self.__init_iotupl_port()
        # Traffic from gateway, i.e. id=10 is harded, it is allowed.
        # Note: Conceptionally, this rule refers to the iotupl-port, but there is no need to re-send it, because the port-number / datapath-id is not encoded
        logging.info("Pushing traffic from gateway rule")
        incoming_gw_brodcast_match = parser.OFPMatch(metadata=0x10)
        incoming_gw_brodcast_instruction = [parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS,[
            parser.OFPActionOutput(ofproto.OFPP_NORMAL)
        ])]
        incoming_gw_brodcast_msg = parser.OFPFlowMod(datapath=datapath, priority=10,table_id=10, match=incoming_gw_brodcast_match, instructions=incoming_gw_brodcast_instruction)
        datapath.send_msg(incoming_gw_brodcast_msg)

        # When a device connects, some iot-device may be attached already. Hence, we need to update all port-Rules
        self.__update_port_broadcast_rules()
        self.__update_port_unicast_rules()

    def __init_iotupl_port(self):
        logging.info("__init_iotupl_port called")
        datapath = self.datapath
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser
        # The iotupl-Port handles mesh-traffic. When re-attached, two rules need to be updated
        # 1. Incoming traffic, MPLS tagged originating from this port switched to table 2
        # 2. Outgoing traffic, needs to be MPLS-Tagged and send using this port
        if self.iot_upl_port_num is not None: # Make sure, to have an iotupl-Port at the bridge
            logging.info("There is a mesh-uplink port - pushing resubmit two table 2 rule for unwrapping MPLS-Traffic")
            # 1. Incomping MPLS-traffic must be passed to de-tagging
            incoming_iot_match = parser.OFPMatch(in_port=self.iot_upl_port_num)
            mpls_untagging_instruction = [parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS,[
                parser.NXActionResubmitTable(table_id=1)
            ])]
            incoming_iotupl_msg =  parser.OFPFlowMod(datapath=datapath, priority=10,table_id=0, match=incoming_iot_match, instructions=mpls_untagging_instruction)
            datapath.send_msg(incoming_iotupl_msg)
            logging.info("Pushing MPLS-Wrapping rules to table 11")
            # 2. handle outgoing MPLS-Traffic in table 11
            outgoing_match = parser.OFPMatch()
            outgoing_instructions = [parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS,[
                parser.NXActionRegMove(src_field="eth_type",dst_field="metadata",n_bits=16, dst_ofs=0),
                parser.OFPActionPushMpls(0x8847),
                parser.NXActionRegMove(src_field="metadata",dst_field="mpls_label",n_bits=16, dst_ofs=0),
                parser.OFPActionPushMpls(0x8847),
                parser.NXActionRegMove(src_field="reg0",dst_field="mpls_label",n_bits=10, dst_ofs=0),
                parser.OFPActionOutput(port=self.iot_upl_port_num)
            ])]
            outgoing_iotupl_msg =  parser.OFPFlowMod(datapath=datapath, priority=10,table_id=11, match=outgoing_match, instructions=outgoing_instructions)
            datapath.send_msg(outgoing_iotupl_msg)


    def __clearTables(self):
        logging.info("__clearTables called")
        datapath = self.datapath
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser

      # Flush table 0 and 10, 11 because they are needed.
        for table in [0,10,11]:
            logging.info("Clearing table %i",table)
            msg = parser.OFPFlowMod(datapath, 0, 0, table ,ofproto.OFPFC_DELETE, 0, 0,1,ofproto.OFPCML_NO_BUFFER,ofproto.OFPP_ANY,ofproto.OFPG_ANY, 0,parser.OFPMatch(), [])
            datapath.send_msg(msg)



    # Adapt broadcast-related rules to a new port-configuration
    def __update_port_broadcast_rules(self):
        logging.info("__update_port_broadcat_rules")
        datapath = self.datapath
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser
        vlan_to_connected_destination_ports = {}
        for vlan in self.allowed_iot_traffic.keys(): # Take care of all "known" vlans, e.g. ports that traffic can originate from
            logging.info("Establing rules for: %s", vlan)
            target_ports = {} # Contruct set iterativly by adding destination ports for switching
            for target in MeshNode.allowed_iot_traffic[vlan]: # Iterate over possible targets
                logging.info("Checking target: %s",target)
                if target in self.connected_vlans: # Connected Port
                    logging.info("Target is connected locally")
                    target_port = self.connected_vlans[target] # is the port connected? If not, no problem. Broadcast-Traffic will be forwarded to the mesh / gateway anyway
                    target_ports += target_port # Add List to the target ports
                else:
                    logging.info("Target is not connected locally")
            vlan_to_connected_destination_ports[vlan] = target_ports

        # After created a list of all connected_destination by vlan, implement the following strategy
        # 1. For each VLAN with connected ports, switch Mesh-traffic to connected destination ports.
        # 2. For each vlan 1) Get connected port 2) get destination ports 3) Forward target to all ports (excl. self) and tag it for mesh
        # Let's start with 1
        logging.info("Brodcast-rules 1/2 - broadcast-traffic from mesh to target-port an mesh")
        for vlan in self.allowed_iot_traffic.keys():
            logging.info("Handling vlan: %s",vlan)
            if vlan in vlan_to_connected_destination_ports:
                logging.info("%s has conencted ports", vlan)
                connected_target_ports = vlan_to_connected_destination_ports[vlan]
                match = parser.OFPMatch(metadata=self.__vlan_id(vlan),eth_dst=("01:00:00:00:00:00","01:00:00:00:00:00"))
                output_actions = {}
                for port in connected_target_ports:
                    logging.info("port: '%s' is locally connected", port)
                    output_actions += parser.OFPActionOutput(port)
                logging.info("Sending rule for incoming broadcast-traffic")
                datapath.send_msg(parser.OFPFlowMod(datapath=datapath, table_id=10, match=match, priority=10, instructions=[parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS,output_actions)]))
            else:
                logging.info("'%s' is not locally connected - not installing any rules for originating traffic", vlan )
        # Starting with 2
        logging.info("Broadcast-rules 2/2 - broadcast-traffic from connected ports to target-ports and mesh")
        for source_port in self.connected_vlans: 
            logging.info("Handling connected port: '%s'",source_port)
            output_actions = []
            if source_port in self.allowed_iot_traffic:
                logging.info("Port %s has ACL rules", source_port )
                whitelist = self.allowed_iot_traffic[source_port]
                for possible_destination_port in whitelist:
                    logging.info("Handling allowed destination %s", possible_destination_port)
                    if possible_destination_port in self.connected_vlans:
                        logging.info("Destination is locally connected")
                        output_actions += [parser.OFPActionOutput(port)]
                    else:
                        logging.info("Destination is not locally connected")
            logging.info("Sending output rule accorind to ports an mesh")
            vlanid = self.__vlan_id(source_port)
            output_actions += [parser.OFPActionSetField(reg0=vlanid)]
            output_actions += [parser.NXActionResubmitTable(table_id=11)] # Resumbit to table 11 for MPLS tagging and sending to mesh
            src_mac=self.vlan_to_mac[source_port]
            vlan_match = parser.OFPMatch(in_port=vlanid,eth_src=src_mac,eth_dst=("01:00:00:00:00:00","01:00:00:00:00:00"))
            datapath.send_msg(parser.OFPFlowMod(datapath=datapath, table_id=0, priority=10, match=vlan_match, instructions=[parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS,output_actions)]))

    # Adapt unicast port rules to a new configuration
    def __update_port_unicast_rules(self):
        logging.info("__update_port_unicast_rules cllaed")
        datapath = self.datapath
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser
        
        # Traffic from connected IoT-devices
        # 1. Unicast-Traffic: iterate over

        for vlan in self.connected_vlans.keys(): # Handle all connected ports
            logging.info("Handling connected vlan / port: '%s'",vlan)
            # We don't need to handle traffic from the gateway, because this is allowed all the time. First, check unicast traffic
            # Construct unicast devices to device rules for all allowed devices
            allowed_devices = MeshNode.allowed_iot_traffic[vlan]
            in_port = self.connected_vlans[vlan]
            src_mac = MeshNode.vlan_to_mac[vlan]

            # Add a "default to mesh rule", so that traffic to gateway works even if the destination mac is not availble
            incoming_unicast_match = parser.OFPMatch(in_port=in_port,eth_src=src_mac)
            incoming_unicast_match_instruction = [parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS,[parser.OFPActionSetField(reg0=self.__vlan_id(vlan)), 
                        parser.NXActionResubmitTable(table_id=11)])]
            self.datapath.send_msg(parser.OFPFlowMod(datapath=datapath, priority=5, match=incoming_unicast_match, instructions=incoming_unicast_match_instruction))
            
            for device in allowed_devices:
                logging.info("Checking allowed target device: '%s'",device )
                target_vlan_id = self.__vlan_id(device)
                dest_mac = MeshNode.vlan_to_mac[device]
                if device in self.connected_vlans:
                    logging.info("Device '%s' is locally connected, adding corresponding switch rule based on mac-address",device )
                    incoming_unicast_match = parser.OFPMatch(in_port=in_port,eth_src=src_mac, eth_dst=dest_mac)
                    out_port = self.connected_vlans[device]
                    incoming_unicast_match_instruction = [parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS,[
                        parser.OFPActionOutput(out_port)
                    ])]
                    self.datapath.send_msg(parser.OFPFlowMod(datapath=datapath, priority=10, match=incoming_unicast_match, instructions=incoming_unicast_match_instruction))
                else: 
                    # Add a corresponding rule for receiving packets
                    mesh_incoming_unicast_match = parser.OFPMatch(metadata=target_vlan_id, eth_dst = src_mac)
                    mesh_incoming_unicast_instruction =  [parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS,[
                        parser.OFPActionOutput(port=in_port)
                    ])]
                    self.datapath.send_msg(parser.OFPFlowMod(datapath=datapath, priority=10, match=mesh_incoming_unicast_match, instructions=mesh_incoming_unicast_instruction))

    def __vlan_id(self, vlan_name): 
        return int(vlan_name.replace(b"iot_",b""),16)
